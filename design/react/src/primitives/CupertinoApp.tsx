import type { CSSProperties, ReactNode } from "react";

export interface CupertinoAppProps {
  children: ReactNode;
  /** Force light or dark. Omit to follow the system setting. */
  brightness?: "light" | "dark";
  /** Page background. Defaults to `systemBackground`; use `systemGroupedBackground` behind grouped forms. */
  background?: "systemBackground" | "systemGroupedBackground";
  style?: CSSProperties;
}

/**
 * The app root, standing in for Flutter's `CupertinoApp`: applies the system
 * font, label color, page background, and the light/dark palette. Wrap every
 * screen in it.
 */
export function CupertinoApp({
  children,
  brightness,
  background = "systemBackground",
  style,
}: CupertinoAppProps) {
  const classes = ["cupertino-app"];
  if (brightness === "dark") classes.push("cupertino-dark");
  if (brightness === "light") classes.push("cupertino-light");
  return (
    <div
      className={classes.join(" ")}
      style={{
        background:
          background === "systemGroupedBackground"
            ? "var(--cupertino-system-grouped-background)"
            : "var(--cupertino-system-background)",
        ...style,
      }}
    >
      {children}
    </div>
  );
}
