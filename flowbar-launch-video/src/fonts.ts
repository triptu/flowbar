import { loadFont as loadDMSans } from "@remotion/google-fonts/DMSans";
import { loadFont as loadInstrumentSerif } from "@remotion/google-fonts/InstrumentSerif";

const { fontFamily: dmSansFamily } = loadDMSans("normal", {
  weights: ["400", "500", "600", "700"],
  subsets: ["latin"],
});

const { fontFamily: serifFamily } = loadInstrumentSerif("normal", {
  weights: ["400"],
  subsets: ["latin"],
});

export const FONT_BODY = dmSansFamily;
export const FONT_SERIF = serifFamily;
