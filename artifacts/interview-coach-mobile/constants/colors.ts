/**
 * Semantic design tokens for the mobile app.
 *
 * These tokens mirror the naming conventions used in web artifacts (index.css)
 * so that multi-artifact projects share a cohesive visual identity.
 *
 * Replace the placeholder values below with values that match the project's
 * brand. If a sibling web artifact exists, read its index.css and convert the
 * HSL values to hex so both artifacts use the same palette.
 *
 * To add dark mode, add a `dark` key with the same token names.
 * The useColors() hook will automatically pick it up.
 */

const colors = {
  light: {
    text: '#10213A',
    tint: '#4268E8',
    background: '#F7F8FC',
    foreground: '#10213A',
    card: '#FFFFFF',
    cardForeground: '#10213A',
    primary: '#4268E8',
    primaryForeground: '#FFFFFF',
    secondary: '#EEF1FA',
    secondaryForeground: '#273B65',
    muted: '#F0F2F8',
    mutedForeground: '#71809B',
    accent: '#DDF7ED',
    accentForeground: '#147554',
    destructive: '#C94B61',
    destructiveForeground: '#FFFFFF',
    border: '#E2E6F0',
    input: '#D7DDEB',
    ink: '#10213A',
    navy: '#17294E',
    mint: '#BCEFD9',
    coral: '#F29B84',
    yellow: '#F5C968',
    violet: '#8E82E8',
    success: '#28A477',
  },
  dark: {
    text: '#F6F8FF',
    tint: '#8EA6FF',
    background: '#0E1629',
    foreground: '#F6F8FF',
    card: '#17223A',
    cardForeground: '#F6F8FF',
    primary: '#8EA6FF',
    primaryForeground: '#101A31',
    secondary: '#202D49',
    secondaryForeground: '#DCE4FF',
    muted: '#1C2942',
    mutedForeground: '#9AA9C5',
    accent: '#123D3A',
    accentForeground: '#9DE7C8',
    destructive: '#EF8799',
    destructiveForeground: '#2D1019',
    border: '#2B3954',
    input: '#34425E',
    ink: '#F6F8FF',
    navy: '#233862',
    mint: '#63CFA4',
    coral: '#F6A08E',
    yellow: '#E4B759',
    violet: '#AAA0FF',
    success: '#63D3AB',
  },
  radius: 18,
};

export default colors;
