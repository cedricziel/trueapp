import type { ReactNode } from "react";
import {
  CupertinoApp,
  CupertinoIcon,
  type ColorValue,
  type CupertinoIconName,
} from "@truenas-manager/ui";

const ALL_ICONS: CupertinoIconName[] = [
  "app",
  "arrow_2_circlepath",
  "arrow_clockwise",
  "arrow_down",
  "arrow_down_circle",
  "arrow_up",
  "arrow_up_circle",
  "back",
  "bell",
  "camera",
  "chart_bar",
  "checkmark_circle",
  "chevron_down",
  "chevron_right",
  "chevron_up",
  "circle",
  "cloud_upload",
  "delete",
  "desktopcomputer",
  "device_desktop",
  "exclamationmark_bubble",
  "exclamationmark_circle",
  "exclamationmark_shield",
  "gear",
  "globe",
  "heart",
  "house",
  "lock",
  "lock_open",
  "lock_shield",
  "lock_slash",
  "memories",
  "question_circle",
  "refresh",
  "settings",
  "shield",
  "sidebar_left",
  "sidebar_right",
  "speedometer",
  "square_stack_3d_down_right",
  "tag",
  "time",
  "waveform_path",
  "wifi",
  "wifi_exclamationmark",
  "wifi_slash",
  "heart_fill",
  "star_fill",
  "house_fill",
  "checkmark_circle_fill",
  "xmark_circle_fill",
  "minus_circle_fill",
  "exclamationmark_circle_fill",
  "arrow_up_circle_fill",
  "exclamationmark_triangle",
  "exclamationmark_triangle_fill",
];

function Pane({
  dark,
  width,
  children,
}: {
  dark?: boolean;
  width: number;
  children: ReactNode;
}) {
  return (
    <CupertinoApp
      brightness={dark ? "dark" : "light"}
      style={{ padding: 16, width }}
    >
      {children}
    </CupertinoApp>
  );
}

function Grid() {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(6, 1fr)",
        gap: "14px 8px",
      }}
    >
      {ALL_ICONS.map((name) => (
        <div
          key={name}
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 6,
          }}
        >
          <CupertinoIcon
            icon={name}
            color={name.endsWith("_fill") ? "systemBlue" : undefined}
          />
          <span
            style={{
              fontSize: 10,
              color: "var(--cupertino-secondary-label)",
              textAlign: "center",
              wordBreak: "break-word",
            }}
          >
            {name}
          </span>
        </div>
      ))}
    </div>
  );
}

const STATUS: { icon: CupertinoIconName; color: ColorValue; label: string }[] =
  [
    {
      icon: "checkmark_circle_fill",
      color: "systemGreen",
      label: "tank ONLINE",
    },
    {
      icon: "exclamationmark_triangle_fill",
      color: "systemOrange",
      label: "backup DEGRADED",
    },
    { icon: "xmark_circle_fill", color: "systemRed", label: "scratch FAULTED" },
    {
      icon: "arrow_clockwise",
      color: "systemBlue",
      label: "pool.scrub running",
    },
    { icon: "wifi_slash", color: "systemGrey", label: "Office Mini offline" },
  ];

function ColorsAndSizes() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {STATUS.map((s) => (
          <div
            key={s.label}
            style={{ display: "flex", alignItems: "center", gap: 10 }}
          >
            <CupertinoIcon icon={s.icon} color={s.color} size={22} />
            <span style={{ fontSize: 15 }}>{s.label}</span>
          </div>
        ))}
      </div>
      <div style={{ display: "flex", alignItems: "flex-end", gap: 16 }}>
        {[16, 20, 24, 32, 44].map((size) => (
          <div
            key={size}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 4,
            }}
          >
            <CupertinoIcon
              icon="square_stack_3d_down_right"
              size={size}
              color="systemBlue"
            />
            <span
              style={{
                fontSize: 11,
                color: "var(--cupertino-secondary-label)",
              }}
            >
              {size}px
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

export const AllIconsLight = () => (
  <Pane width={560}>
    <Grid />
  </Pane>
);

export const AllIconsDark = () => (
  <Pane dark width={560}>
    <Grid />
  </Pane>
);

export const ColorsAndSizesLight = () => (
  <Pane width={320}>
    <ColorsAndSizes />
  </Pane>
);

export const ColorsAndSizesDark = () => (
  <Pane dark width={320}>
    <ColorsAndSizes />
  </Pane>
);
