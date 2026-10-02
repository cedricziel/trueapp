import { resolveColor, type ColorValue } from "../colors";

const ALPHAS = [47, 47, 47, 47, 72, 97, 122, 147];

export interface CupertinoActivityIndicatorProps {
  /** Spinner radius in px. Flutter's default is 10. */
  radius?: number;
  /** Tick color. Defaults to the iOS inactive grey (#3C3C44 light, #EBEBF5 dark). */
  color?: ColorValue;
  /** Whether the spinner rotates. Static renders show the same tick pattern. */
  animating?: boolean;
}

/**
 * Flutter's `CupertinoActivityIndicator`: the iOS eight-tick spinner.
 */
export function CupertinoActivityIndicator({
  radius = 10,
  color = "var(--cupertino-activity-indicator)",
  animating = true,
}: CupertinoActivityIndicatorProps) {
  const size = radius * 2;
  const tickWidth = (radius / 10) * 2;
  const fill = resolveColor(color);
  return (
    <svg
      role="progressbar"
      aria-label="Loading"
      width={size}
      height={size}
      viewBox={`${-radius} ${-radius} ${size} ${size}`}
      className={animating ? "cupertino-activity-indicator" : undefined}
      style={{ display: "block", flexShrink: 0 }}
    >
      {ALPHAS.map((alpha, i) => (
        <rect
          key={i}
          x={-tickWidth / 2}
          y={-radius}
          width={tickWidth}
          height={radius - radius / 3}
          rx={tickWidth / 2}
          fill={fill}
          opacity={alpha / 255}
          transform={`rotate(${i * 45})`}
        />
      ))}
    </svg>
  );
}
