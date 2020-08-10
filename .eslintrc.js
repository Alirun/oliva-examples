module.exports = {
  'env': {
    'node': true,
    'es6': true,
    'mocha': true
  },
  'extends': [
    'eslint:recommended'
  ],
  'parserOptions': {
    'ecmaVersion': 2018,
  },
  'rules': {
    'indent': [
      'error',
      2,
      { 'SwitchCase': 1 }
    ],
    'linebreak-style': [
      'error',
      'unix'
    ],
    'quotes': [
      'error',
      'single'
    ],
    'semi': [
      'error',
      'never'
    ],
    'brace-style': [
      'error'
    ],
    'object-shorthand': [
      'error'
    ],
    'eol-last': [
      'error',
      'always'
    ],
    'spaced-comment': [
      'error',
      'always'
    ],
    'keyword-spacing': [
      'error'
    ],
    'no-multi-spaces': [
      'error'
    ],
    'block-spacing': [
      'error'
    ],
    'comma-spacing': [
      'error'
    ],
    'arrow-spacing': [
      'error'
    ],
    'rest-spread-spacing': [
      'error',
      'never'
    ],
    'space-before-blocks': [
      'error'
    ],
    'key-spacing': [
      'error'
    ]
  }
}
