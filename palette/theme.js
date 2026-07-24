export const hsl = (
  hue,
  saturation,
  lightness,
) => ({
  hue,
  saturation,
  lightness,
});

export const base = {
  bg: hsl(231, 47, 6),
  fg: hsl(60, 30, 96),
  selection: hsl(235, 49, 15),
  comment: hsl(221, 23, 42),
  red: hsl(0, 100, 67),
  orange: hsl(31, 100, 71),
  yellow: hsl(65, 92, 76),
  beige: hsl(42, 45, 74),
  golden_yellow: hsl(45, 90, 65),
  string_gray: hsl(220, 12, 68),
  green: hsl(135, 94, 65),
  purple: hsl(265, 89, 78),
  cyan: hsl(191, 97, 77),
  pink: hsl(326, 100, 74),
  bright_red: hsl(0, 100, 72),
  bright_green: hsl(137, 100, 71),
  bright_yellow: hsl(60, 100, 82),
  bright_blue: hsl(270, 100, 84),
  bright_magenta: hsl(318, 100, 79),
  bright_cyan: hsl(180, 100, 82),
  bright_white: hsl(0, 0, 100),
  menu: hsl(235, 14, 15),
  visual: hsl(222, 14, 28),
  gutter_fg: hsl(223, 14, 34),
  nontext: hsl(217, 10, 26),
  white: hsl(219, 14, 71),
  black: hsl(233, 14, 11),
};

const expressivePalette = (
  hue,
  grayHue = hue,
  overrides = {},
) => ({
  darkest: hsl(hue, 22, 27),
  dim: hsl(hue, 44, 30),
  muted: hsl(hue, 19, 47),
  soft: hsl(hue, 32, 50),
  main: hsl(hue, 52, 51),
  accent: hsl(hue, 66, 58),
  bright: hsl(hue, 82, 69),
  light: hsl(hue, 100, 82),
  gray_dim: hsl(grayHue, 9, 50),
  gray: hsl(grayHue, 10, 62),
  gray_light: hsl(grayHue, 15, 80),
  gray_warm: hsl(hue, 10, 61),
  ...overrides,
});

export const blue = expressivePalette(210, 220, {
  darkest: hsl(230, 78, 59),
});

export const green = expressivePalette(150, 160, {
  gray_dim: hsl(160, 9, 42),
});

export const gold = expressivePalette(50, 222, {
  soft: hsl(49, 32, 50),
  bright: hsl(51, 82, 69),
  gray_light: hsl(70, 5, 30),
});

// Wider than gold without moving its most frequently used shades far from the
// familiar yellow-gold center. Darkest/light are intentional warm/cool
// outliers at the requested 20° and 80° endpoints.
export const gold2 = expressivePalette(50, 222, {
  darkest: hsl(20, 34, 28),
  dim: hsl(30, 48, 31),
  muted: hsl(42, 22, 47),
  soft: hsl(47, 35, 50),
  main: hsl(50, 54, 52),
  accent: hsl(55, 68, 59),
  bright: hsl(58, 80, 70),
  light: hsl(80, 76, 83),
  gray_dim: hsl(220, 9, 49),
  gray: hsl(222, 10, 62),
  gray_light: hsl(70, 7, 78),
  gray_warm: hsl(50, 12, 61),
});

export const gray = expressivePalette(220, 220, {
  darkest: hsl(225, 10, 26),
  dim: hsl(222, 11, 32),
  muted: hsl(220, 9, 46),
  soft: hsl(218, 10, 52),
  main: hsl(216, 12, 58),
  accent: hsl(214, 14, 65),
  bright: hsl(212, 16, 73),
  light: hsl(210, 18, 83),
  gray_dim: hsl(222, 8, 48),
  gray: hsl(220, 9, 62),
  gray_light: hsl(216, 12, 80),
  gray_warm: hsl(35, 9, 61),
});

export const indigo = expressivePalette(240, 235, {
  darkest: hsl(245, 30, 28),
  dim: hsl(242, 48, 32),
  muted: hsl(238, 20, 48),
  soft: hsl(238, 38, 52),
  main: hsl(240, 54, 56),
  accent: hsl(244, 68, 63),
  bright: hsl(240, 82, 73),
  light: hsl(235, 100, 86),
});

export const violet = expressivePalette(275, 270, {
  darkest: hsl(285, 28, 28),
  dim: hsl(280, 45, 32),
  muted: hsl(272, 20, 48),
  soft: hsl(274, 36, 53),
  main: hsl(275, 52, 57),
  accent: hsl(278, 66, 64),
  bright: hsl(276, 80, 74),
  light: hsl(272, 96, 86),
  gray: hsl(270, 10, 72),
});

export const blush = expressivePalette(350, 345, {
  darkest: hsl(5, 26, 29),
  dim: hsl(358, 42, 33),
  muted: hsl(350, 23, 49),
  soft: hsl(348, 34, 54),
  main: hsl(350, 48, 58),
  accent: hsl(352, 61, 66),
  bright: hsl(354, 72, 75),
  light: hsl(356, 82, 86),
  gray_warm: hsl(8, 12, 63),
});

export const pink = expressivePalette(325, 320);

export const cyan = expressivePalette(185, 190);

export const theme = {
  base,
  monochrome: {
    blue,
    green,
    gold,
    gold2,
    gray,
    indigo,
    violet,
    blush,
    pink,
    cyan,
  },
};
