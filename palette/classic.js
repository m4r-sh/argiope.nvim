export const hsl = (hue, saturation, lightness) => ({
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

const expressivePalette = (hue, grayHue = hue, overrides = {}) => ({
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

const blue = expressivePalette(210, 220, {
  darkest: hsl(230, 78, 59),
});

const green = expressivePalette(150, 160, {
  gray_dim: hsl(160, 9, 42),
});

const gold = expressivePalette(50, 222, {
  soft: hsl(49, 32, 50),
  bright: hsl(51, 82, 69),
  gray_light: hsl(70, 5, 30),
});

const gold2 = expressivePalette(50, 222, {
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

const gray = expressivePalette(220, 220, {
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

const indigo = expressivePalette(240, 235, {
  darkest: hsl(245, 30, 35),
  dim: hsl(242, 48, 42),
  muted: hsl(238, 20, 59),
  soft: hsl(238, 38, 64),
  main: hsl(240, 54, 68),
  accent: hsl(244, 68, 74),
  bright: hsl(240, 82, 83),
  light: hsl(235, 100, 92),
  gray_dim: hsl(235, 9, 57),
  gray: hsl(235, 10, 70),
  gray_light: hsl(235, 15, 87),
  gray_warm: hsl(240, 12, 69),
});

const violet = expressivePalette(275, 270, {
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

const blush = expressivePalette(325, 320, {
  darkest: hsl(330, 20, 34),
  dim: hsl(327, 28, 40),
  muted: hsl(325, 18, 56),
  soft: hsl(323, 26, 61),
  main: hsl(325, 36, 66),
  accent: hsl(327, 45, 73),
  bright: hsl(329, 54, 81),
  light: hsl(331, 65, 90),
  gray_dim: hsl(320, 9, 57),
  gray: hsl(320, 10, 70),
  gray_light: hsl(320, 15, 87),
  gray_warm: hsl(325, 10, 69),
});

const ember = expressivePalette(15, 25, {
  darkest: hsl(15, 26, 35),
  dim: hsl(19, 41, 41),
  muted: hsl(22, 22, 58),
  soft: hsl(24, 34, 64),
  main: hsl(27, 50, 69),
  accent: hsl(31, 66, 75),
  bright: hsl(35, 82, 83),
  light: hsl(41, 96, 91),
  gray_dim: hsl(32, 9, 57),
  gray: hsl(32, 10, 70),
  gray_light: hsl(32, 15, 87),
  gray_warm: hsl(27, 12, 69),
});

const slate = expressivePalette(155, 165, {
  darkest: hsl(155, 14, 25),
  dim: hsl(155, 21, 30),
  muted: hsl(155, 15, 43),
  soft: hsl(155, 22, 49),
  main: hsl(155, 30, 54),
  accent: hsl(155, 38, 61),
  bright: hsl(155, 48, 70),
  light: hsl(155, 60, 83),
  gray_dim: hsl(165, 9, 48),
  gray: hsl(165, 10, 62),
  gray_light: hsl(165, 15, 80),
  gray_warm: hsl(155, 12, 61),
});

const pink = expressivePalette(325, 320);
const cyan = expressivePalette(185, 190);

export const monochrome = {
  blue,
  green,
  gold,
  gold2,
  gray,
  indigo,
  violet,
  blush,
  ember,
  slate,
  pink,
  cyan,
};
