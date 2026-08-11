// Hue families are deliberately independent from theme profiles. A user's
// language-to-family assignments therefore survive every interpretation.
export const families = {
  blue: { hue: 250, neutralHue: 255 },
  green: { hue: 150, neutralHue: 160 },
  gold: { hue: 95, neutralHue: 255 },
  gold2: {
    hue: 95,
    neutralHue: 255,
    hueList: [45, 62, 78, 88, 95, 101, 106, 112],
  },
  gray: { hue: 255, neutralHue: 255, saturationScale: 0.08 },
  indigo: { hue: 275, neutralHue: 270 },
  violet: { hue: 305, neutralHue: 300 },
  blush: { hue: 355, neutralHue: 350 },
  ember: { hue: 55, neutralHue: 65 },
  slate: { hue: 165, neutralHue: 175 },
  pink: { hue: 345, neutralHue: 340 },
  cyan: { hue: 210, neutralHue: 220 },
};
