The config is invalid. The `nestedEntities.defaultContact` entry has value
`owner`, but `owner` is not a key that exists in `entities` (the only
`entities` keys are `company` and `contact`), and the schema requires every
`nestedEntities` value to be a key that exists in `entities`. `mode:
session-random` is a valid mode string and `customFields` is optional and
well-formed, so neither of those is a problem.
