module.exports = {
  mode: "jit",
  purge: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      keyframes: {
        slide: {
          "0%, 100%": {
            transform: "translate(512px, 0px)",
          },
          "25%, 75%": {
            transform: "translate(0px, 0px)",
          },
        },
        wiggle: {
          "0%, 100%": { transform: "rotate(-3deg)" },
          "25%, 50%": { transform: "rotate(3deg)" },
        },
      },
      animation: {
        slide: "slide 4s ease-in-out forwards",
        wiggle: "wiggle 1s ease-in-out infinite",
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
};
