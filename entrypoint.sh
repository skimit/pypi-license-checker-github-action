#!/bin/bash
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "\"${last_command}\" command exited with exit code $?."; cat ~/cmd.log' EXIT

cd /github/workspace || exit 1

if [ ! -f requirements.txt ] && [ ! -f pyproject.toml ]; then
    printf "\n\nCouldn't find requirements.txt nor pyproject.toml files. Ignoring...";
    exit 0;
fi

python -m pip install --upgrade pip &> ~/cmd.log

if [ -f pyproject.toml ]; then
    pip install poetry &> ~/cmd.log
    poetry source add --secondary artifactory https://deeperinsights.jfrog.io/artifactory/api/pypi/deeper-insights-pypi/simple
    poetry config http-basic.artifactory $EXTRA_INDEX_URL_USERNAME $EXTRA_INDEX_URL_PASSWORD
    poetry export -f requirements.txt --output requirements.txt --without-hashes &> ~/cmd.log
fi

python -m venv env

# shellcheck source=/dev/null
. env/bin/activate

# Update pip inside the virtual environment
python -m pip install --upgrade pip &> ~/cmd.log

pip install --no-cache-dir -r requirements.txt --extra-index-url https://"$EXTRA_INDEX_URL_USERNAME":"$EXTRA_INDEX_URL_PASSWORD"@"$EXTRA_INDEX_URL" &> ~/cmd.log

if [ -f allowed_dependencies.txt ]; then
    while IFS="" read -r DEPENDENCY || [ -n "$DEPENDENCY" ]
    do
        printf "\n\nUninstalling %s...\n\n" "$DEPENDENCY"
        pip uninstall "$DEPENDENCY" --yes &> ~/cmd.log
    done < allowed_dependencies.txt
fi

[ $? -eq 0 ] || (printf "\n😵 Something went wrong installing dependencies... Please, check logs above.\n\n" && exit 1)

pip install pip-licenses &> ~/cmd.log

printf "\n👉🏽 Validating installed dependencies licenses...\n\n"

pip-licenses --from=mixed --format=confluence --fail-on="GNU General Public License (GPL); GNU General Public License v2 (GPLv2); GNU General Public License v2 or later (GPLv2+); GNU General Public License v3 (GPLv3); GNU General Public License v3 or later (GPLv3+); GNU Lesser General Public License v2 (LGPLv2); GNU Lesser General Public License v2 or later (LGPLv2+); GNU Lesser General Public License v3 (LGPLv3); GNU Lesser General Public License v3 or later (LGPLv3+); GNU Library or Lesser General Public License (LGPL); Mozilla Public License 1.0 (MPL); Mozilla Public License 1.1 (MPL 1.1); Mozilla Public License 2.0 (MPL 2.0); Eclipse Public License 1.0 (EPL-1.0); Eclipse Public License 2.0 (EPL-2.0)"
