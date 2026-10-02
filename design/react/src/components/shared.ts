import type { CSSProperties } from "react";

/** The grey-6, hairline-bordered, 12px-radius card every list card shares. */
export function cardStyle(bordered = true): CSSProperties {
  return {
    padding: 16,
    background: "var(--cupertino-system-grey6)",
    borderRadius: 12,
    border: bordered ? "0.5px solid var(--cupertino-separator)" : undefined,
  };
}

export const secondaryText = "var(--cupertino-system-grey)";

/** The app's compact byte formatter (`1.2GB`), as used by pool cards. */
export function formatBytesCompact(bytes: number): string {
  const k = 1024;
  if (bytes < k) return `${bytes}B`;
  if (bytes < k ** 2) return `${(bytes / k).toFixed(1)}KB`;
  if (bytes < k ** 3) return `${(bytes / k ** 2).toFixed(1)}MB`;
  if (bytes < k ** 4) return `${(bytes / k ** 3).toFixed(1)}GB`;
  return `${(bytes / k ** 4).toFixed(1)}TB`;
}

/** The app's spaced byte formatter (`1.2 GB`), as used by app cards. */
export function formatBytes(bytes: number): string {
  const k = 1024;
  if (bytes < k) return `${bytes} B`;
  if (bytes < k ** 2) return `${(bytes / k).toFixed(1)} KB`;
  if (bytes < k ** 3) return `${(bytes / k ** 2).toFixed(1)} MB`;
  return `${(bytes / k ** 3).toFixed(1)} GB`;
}
