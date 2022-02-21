const { environment } = require('@rails/webpacker')

// Copy JSON files to the output, rather than reading them as JS
environment.loaders.append('json', {
  type: 'javascript/auto',
  test: /\.json$/,
  use: [{ loader: 'file-loader' }]
})

// resolve-url-loader must be used before sass-loader
// See https://github.com/rails/webpacker/blob/master/docs/css.md#resolve-url-loader
environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader'
})

module.exports = environment
