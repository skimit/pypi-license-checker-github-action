#!/bin/bash
set -e
touch ~/cmd.log
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'printf "Error!\n\n%s command exited with exit code $?.\n\n\n\n" "${last_command}"; cat ~/cmd.log' EXIT

cd /github/workspace || exit 1

if [ ! -f requirements.txt ] && [ ! -f pyproject.toml ]; then
    printf "\n\nCouldn't find requirements.txt nor pyproject.toml files. Ignoring..."
    exit 0
fi

# Check if EXTRA_SYSTEM_DEPENDENCIES is set
if [ -n "$EXTRA_SYSTEM_DEPENDENCIES" ]; then
    printf "\n\nInstalling extra system dependencies: '%s'" "$EXTRA_SYSTEM_DEPENDENCIES"
    apt-get update &>~/cmd.log
    # shellcheck disable=SC2086
    apt-get install -y gcc $EXTRA_SYSTEM_DEPENDENCIES &>~/cmd.log
    printf "\n\nExtra system dependencies installed successfully!"
fi

python -m pip install --upgrade pip &>~/cmd.log

if [ -f pyproject.toml ]; then
    if [ $(grep "tool.poetry" pyproject.toml) -ge 1 ]; then
        ## PROJECT USES poetry
        python -m pip install --upgrade pip &>~/cmd.log
        pip install poetry &> ~/cmd.log

        # Check if required environment variables are set
        if [[ -n "$EXTRA_INDEX_URL" || -n "$EXTRA_INDEX_URL_USERNAME" || -n "$EXTRA_INDEX_URL_PASSWORD" ]]; then
            poetry source add --priority supplemental artifactory "https://$EXTRA_INDEX_URL"
            poetry config http-basic.artifactory "$EXTRA_INDEX_URL_USERNAME" "$EXTRA_INDEX_URL_PASSWORD"
        fi
        poetry self add poetry-plugin-export &>~/cmd.log
        poetry export -f requirements.txt --output requirements.txt --without-hashes --all-extras --without dev &> ~/cmd.log
    elif [ $(grep "tool.uv" pyproject.toml) -ge 1 ]; then
        if [[ -n "$EXTRA_INDEX_URL" || -n "$EXTRA_INDEX_URL_USERNAME" || -n "$EXTRA_INDEX_URL_PASSWORD" ]]; then
	    echo "\nmachine ${EXTRA_INDEX_URL}" >> ~/.netrc
	    echo "login ${EXTRA_INDEX_URL_USERNAME}" >> ~/.netrc
	    echo "password ${EXTRA_INDEX_URL_PASSWORD}" >> ~/.netrc
        fi
	/bin/uv export --all-extras --no-dev --no-hashes --output-file requirements.txt &> cmd.log
    else
	printf "\n\nFound a pyproject.toml, but couldn't find a config for poetry or uv";
	exit 1;
    fi
fi

python -m venv env

# shellcheck disable=SC1091
. env/bin/activate

# Update pip inside the virtual environment
python -m pip install --upgrade pip wheel &>~/cmd.log

# Check if required environment variables are set
if [[ -n "$EXTRA_INDEX_URL" || -n "$EXTRA_INDEX_URL_USERNAME" || -n "$EXTRA_INDEX_URL_PASSWORD" ]]; then
    EXTRA_INDEX_REPOSITORY="https://$EXTRA_INDEX_URL_USERNAME:$EXTRA_INDEX_URL_PASSWORD@$EXTRA_INDEX_URL"
fi

pip install --no-cache-dir -r requirements.txt --extra-index-url "$EXTRA_INDEX_REPOSITORY" &>~/cmd.log

if [ -f allowed_dependencies.txt ]; then
    sed -i '/^$/d' allowed_dependencies.txt
    while IFS="" read -r DEPENDENCY || [ -n "$DEPENDENCY" ]; do
        printf "\n\nUninstalling %s...\n\n" "$DEPENDENCY"
        pip uninstall "$DEPENDENCY" --yes &>~/cmd.log
    done <allowed_dependencies.txt
fi

[ $? -eq 0 ] || (printf "\n😵 Something went wrong installing dependencies... Please, check logs above.\n\n" && exit 1)

pip install pip-licenses &>~/cmd.log

printf "\n👉🏽 Validating installed dependencies licenses...\n\n"

pip-licenses --from=mixed --format=confluence --fail-on="GNU General Public License (GPL); GNU General Public License v2 (GPLv2); GNU General Public License v2 or later (GPLv2+); GNU General Public License v3 (GPLv3); GNU General Public License v3 or later (GPLv3+); GNU Lesser General Public License v2 (LGPLv2); GNU Lesser General Public License v2 or later (LGPLv2+); GNU Lesser General Public License v3 (LGPLv3); GNU Lesser General Public License v3 or later (LGPLv3+); GNU Library or Lesser General Public License (LGPL); Mozilla Public License 1.0 (MPL); Mozilla Public License 1.1 (MPL 1.1); Mozilla Public License 2.0 (MPL 2.0); Eclipse Public License 1.0 (EPL-1.0); Eclipse Public License 2.0 (EPL-2.0)"
