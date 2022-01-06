# PyPI License Checker GitHub Action
This action validates project's dependencies licenses, failing if it finds any dependency that uses GPL, MPL, and EPL licensing.

## Example usage

```yaml
name: 'Validate Project Dependencies Licenses'
on: push

jobs:
  validate-project-dependencies:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Validate Dependencies Licenses
        uses: skimit/pypi-license-checker-github-action@v1.1.0
        env:
          EXTRA_INDEX_URL: ${{ secrets.EXTRA_INDEX_URL }}
          EXTRA_INDEX_URL_PULL_TOKEN: ${{ secrets.EXTRA_INDEX_URL_PULL_TOKEN }}
```

## Motivation
[Deeper Insights](https://deeperinsights.com)™ mission is to empower people to use data more effectively and to demystify artificial intelligence. Rather than holding up the common narrative of machines replacing humans, we see how machines can help humans to have easier lives and better businesses. Creating bespoke solutions is part of our DNA. We came up with this solution to help our specialists focus on delivering the best version of their work, using automation to take care of the repetitive tasks.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
