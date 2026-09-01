/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        abyss: {
          950: '#020408',
          900: '#040914',
          800: '#081326',
          700: '#0f2242',
        },
        luminous: {
          cyan: '#00f0ff',
          teal: '#0df2c9',
          blue: '#0284c7',
          glow: 'rgba(0, 240, 255, 0.15)',
        },
        soft: {
          white: '#f1f5f9',
          muted: '#94a3b8',
          dim: '#64748b',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      boxShadow: {
        'glow-sm': '0 0 15px rgba(0, 240, 255, 0.15)',
        'glow-md': '0 0 25px rgba(0, 240, 255, 0.25)',
        'glow-lg': '0 0 45px rgba(0, 240, 255, 0.35)',
      },
      backgroundImage: {
        'abyss-gradient': 'radial-gradient(ellipse at 50% -20%, rgba(2, 132, 199, 0.22), rgba(2, 4, 8, 0.98) 70%)',
        'subtle-radial': 'radial-gradient(circle at 50% 50%, rgba(0, 240, 255, 0.08) 0%, transparent 65%)',
      }
    },
  },
  plugins: [],
}
