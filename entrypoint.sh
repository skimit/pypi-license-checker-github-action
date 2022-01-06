#!/bin/sh -l

cd /github/workspace || exit 1

if [ ! -f requirements.txt ] && [ ! -f pyproject.toml ]; then
    printf "\n\nCouldn't find requirements.txt nor pyproject.toml files. Ignoring...";
    exit 0;
fi

python -m pip install --upgrade pip --quiet 2>&1 1>/dev/null

if [ -f pyproject.toml ]; then
    pip install poetry --quiet > /dev/null 2>&1
    POETRY_HTTP_BASIC_GEMFURY_USERNAME="$EXTRA_INDEX_URL_PULL_TOKEN" poetry export -f requirements.txt --output requirements.txt --without-hashes --quiet 2>&1 1>/dev/null
fi

pip install --no-cache-dir -r requirements.txt --extra-index-url https://"$EXTRA_INDEX_URL_PULL_TOKEN":@"$EXTRA_INDEX_URL" --quiet 2>&1 1>/dev/null 

[ $? -eq 0 ] || exit 1

pip install pip-licenses --quiet > /dev/null 2>&1

printf "\n👉🏽 Validating installed dependencies licenses...\n\n"

pip-licenses --from=mixed --format=confluence --fail-on="GNU General Public License (GPL); GNU General Public License v2 (GPLv2); GNU General Public License v2 or later (GPLv2+); GNU General Public License v3 (GPLv3); GNU General Public License v3 or later (GPLv3+); GNU Lesser General Public License v2 (LGPLv2); GNU Lesser General Public License v2 or later (LGPLv2+); GNU Lesser General Public License v3 (LGPLv3); GNU Lesser General Public License v3 or later (LGPLv3+); GNU Library or Lesser General Public License (LGPL); Mozilla Public License 1.0 (MPL); Mozilla Public License 1.1 (MPL 1.1); Mozilla Public License 2.0 (MPL 2.0); Eclipse Public License 1.0 (EPL-1.0); Eclipse Public License 2.0 (EPL-2.0)"
