/* eslint-disable */

// lint-staged.config.js
module.exports = {
  "(Gemfile|Rakefile)": "bundle exec rubocop --force-exclusion --autocorrect",
  "**/*": "prettier --write --ignore-unknown",
  "**/*.html.erb": ["bundle exec erblint --autocorrect", "bundle exec erblint"],
  "*.builder":
    "bundle exec rubocop --no-server --force-exclusion --autocorrect",
  "*.rake": "bundle exec rubocop --no-server --force-exclusion --autocorrect",
  "*.rb": "bundle exec rubocop --no-server --force-exclusion --autocorrect",
  "bin/*": "bundle exec rubocop --no-server --force-exclusion --autocorrect",
  "**/*.ts?(x)": (filenames) => [
    "tsc -p tsconfig.json --noEmit",
    `biome lint ${filenames.join(" ")}`,
  ],
};
