import { sequential, ramp } from "cusphanger";
import { oklchSrgb } from "nutelch";
import { families } from "./families.js";
import { base as classicBase, monochrome as classicMonochrome } from "./classic.js";
import { profiles } from "./profiles.js";

export const chromaticShadeNames = [
  "darkest",
  "dim",
  "muted",
  "soft",
  "main",
  "accent",
  "bright",
  "light",
];

export const neutralShadeNames = [
  "gray_dim",
  "gray",
  "gray_light",
  "gray_warm",
];

const zip = (names, colors) => Object.fromEntries(
  names.map((name, index) => [name, colors[index]]),
);

const generateRamp = (family, options) => ramp({
  hStart: family.hue,
  hueList: family.hueList,
  total: chromaticShadeNames.length,
  lut: oklchSrgb,
  ...options,
  saturation: options.saturation * (family.saturationScale ?? 1),
});

const generateNeutrals = (family, options) => {
  const colors = sequential({
    hStart: family.neutralHue,
    total: 3,
    lut: oklchSrgb,
    ...options,
  });
  const warm = sequential({
    hStart: family.hue,
    total: 1,
    lut: oklchSrgb,
    saturation: options.saturation,
    lRange: [colors[1].l, colors[1].l],
  })[0];
  return [...colors, warm];
};

const quietRamp = (family, profile) => {
  const chromatic = generateRamp(family, profile.ramp);
  const subdued = generateRamp(family, {
    ...profile.ramp,
    saturation: profile.neutral.saturation,
  });
  // `accent` and `bright` remain available to the quiet capture policy as its
  // two deliberately chromatic focus colors.
  return subdued.map((color, index) => (
    index === 5 || index === 6 ? chromatic[index] : color
  ));
};

const interpretFamily = (family, profile) => {
  let chromatic = profile.quiet
    ? quietRamp(family, profile)
    : generateRamp(family, profile.ramp);
  let neutral = generateNeutrals(family, profile.neutral);
  if (profile.reverse) {
    chromatic = [...chromatic].reverse();
    neutral = [neutral[2], neutral[1], neutral[0], neutral[1]];
  }
  return {
    ...zip(chromaticShadeNames, chromatic),
    ...zip(neutralShadeNames, neutral),
  };
};

export const theme = {
  profiles: {
    classic: {
      background: "dark",
      quiet: false,
      base: classicBase,
      monochrome: classicMonochrome,
    },
    ...Object.fromEntries(
      Object.entries(profiles).map(([profileName, profile]) => [
      profileName,
      {
        background: profile.background,
        quiet: profile.quiet === true,
        base: profile.base,
        monochrome: Object.fromEntries(
          Object.entries(families).map(([familyName, family]) => [
            familyName,
            interpretFamily(family, profile),
          ]),
        ),
      },
      ]),
    ),
  },
};
