module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/views/**/*.svg.erb",
    "./app/components/**/*.html.erb",
    "./app/components/**/*.css",
    "./app/helpers/**/*.rb",
    "./app/style/**/*.css",
    "./app/javascript/**/*.ts",
    "./app/javascript/**/*.tsx",
    "./app/javascript/**/*.js",
    "./app/javascript/**/*.jsx",
  ],
  plugins: [require("@tailwindcss/typography")],
};
