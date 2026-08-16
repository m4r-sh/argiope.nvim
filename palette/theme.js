import { maxChromaAt, sequential, ramp } from "cusphanger";
import { oklchSrgb } from "nutelch";
import { classicLanguagePalettes, families } from "./families.js";
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

const generateRamp = (family, options) => {
  const { fullSaturation = false, ...rampOptions } = options;
  const colors = ramp({
    hStart: family.hue,
    hueList: family.hueList,
    total: chromaticShadeNames.length,
    lut: oklchSrgb,
    ...rampOptions,
    saturation: options.saturation * (family.saturationScale ?? 1),
  });
  if (!fullSaturation || family.saturationScale) {
    return colors;
  }
  return colors.map((color) => ({
    ...color,
    c: maxChromaAt(color.h, color.l, oklchSrgb),
  }));
};

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

const interpretFamily = (familyName, family, profile) => {
  const configuredFamily = {
    ...family,
    ...profile.familyOverrides?.[familyName],
  };
  const rampOptions = {
    ...profile.ramp,
    ...profile.familyRamps?.[familyName],
  };
  let chromatic = generateRamp(configuredFamily, rampOptions);
  let neutral = generateNeutrals(configuredFamily, profile.neutral);
  if (profile.reverse) {
    chromatic = [...chromatic].reverse();
    neutral = [neutral[2], neutral[1], neutral[0], neutral[1]];
  }
  return {
    ...zip(chromaticShadeNames, chromatic),
    ...zip(neutralShadeNames, neutral),
    ...profile.paletteOverrides?.[familyName],
  };
};

const generatedProfile = (profile, displayName) => ({
  displayName,
  background: profile.background,
  palettes: profile.palettes,
  base: profile.base,
  monochrome: Object.fromEntries(
    Object.entries(families).map(([familyName, family]) => [
      familyName,
      interpretFamily(familyName, family, profile),
    ]),
  ),
});

const aurantiaNeon = generatedProfile(
  profiles["aurantia-neon"],
  "Argiope Aurantia Neon",
);

export const theme = {
  profiles: {
    aurantia: {
      displayName: "Argiope Aurantia",
      background: "dark",
      palettes: classicLanguagePalettes,
      base: classicBase,
      monochrome: classicMonochrome,
    },
    versicolor: {
      displayName: "Argiope Versicolor",
      background: "dark",
      syntax: "versicolor",
      palettes: classicLanguagePalettes,
      base: classicBase,
      monochrome: classicMonochrome,
    },
    "aurantia-neon": aurantiaNeon,
    "versicolor-neon": {
      ...aurantiaNeon,
      displayName: "Argiope Versicolor Neon",
      syntax: "versicolor",
    },
    ocyaloides: generatedProfile(profiles.ocyaloides, "Argiope Ocyaloides"),
    trifasciata: generatedProfile(profiles.trifasciata, "Argiope Trifasciata"),
  },
};
