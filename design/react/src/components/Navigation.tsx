import { useEffect, useRef, useState, type ReactNode } from "react";
import {
  CupertinoIcon,
  type CupertinoIconName,
} from "../primitives/CupertinoIcon";
import { AppLogo } from "./Status";

export interface NavigationDestination {
  icon: CupertinoIconName;
  label: string;
}

/** The app's two top-level destinations. */
export const APP_DESTINATIONS: NavigationDestination[] = [
  { icon: "house", label: "Servers" },
  { icon: "settings", label: "Settings" },
];

/** Width (px) at or above which the app switches from the tab bar to the sidebar. */
export const NAVIGATION_BREAKPOINT = 768;

export interface CupertinoTabBarProps {
  items?: NavigationDestination[];
  currentIndex?: number;
  onTap?: (index: number) => void;
}

/**
 * Flutter's `CupertinoTabBar` - the phone-width bottom bar switching between
 * Servers and Settings (the app's `CompactDestinationBar`).
 */
export function CupertinoTabBar({
  items = APP_DESTINATIONS,
  currentIndex = 0,
  onTap,
}: CupertinoTabBarProps) {
  return (
    <nav
      style={{
        display: "flex",
        height: 50,
        background: "var(--cupertino-bar-background)",
        backdropFilter: "blur(20px)",
        borderTop: "0.5px solid var(--cupertino-bar-border)",
      }}
    >
      {items.map((item, i) => {
        const color =
          i === currentIndex
            ? "var(--cupertino-primary)"
            : "var(--cupertino-inactive-gray)";
        return (
          <button
            key={item.label}
            type="button"
            onClick={() => onTap?.(i)}
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              gap: 1,
              border: "none",
              background: "transparent",
              color,
              font: "inherit",
              cursor: "pointer",
            }}
          >
            <CupertinoIcon icon={item.icon} size={26} color={color} />
            <span style={{ fontSize: 10, fontWeight: 500, letterSpacing: 0.1 }}>
              {item.label}
            </span>
          </button>
        );
      })}
    </nav>
  );
}

export interface CupertinoSidebarProps {
  destinations?: NavigationDestination[];
  selectedIndex?: number;
  onDestinationSelected?: (index: number) => void;
  /** Title row content. Defaults to the logo + "TrueNAS Manager". */
  title?: ReactNode;
  /** Width in px. Defaults to 320. */
  width?: number;
}

/**
 * The tablet/desktop sidebar (the `cupertino_sidebar` package's
 * `CupertinoSidebar`): a logo title bar over rounded destination rows; the
 * selected row gets a raised fill and primary-colored label.
 */
export function CupertinoSidebar({
  destinations = APP_DESTINATIONS,
  selectedIndex = 0,
  onDestinationSelected,
  title,
  width = 320,
}: CupertinoSidebarProps) {
  return (
    <aside
      style={{
        width,
        flexShrink: 0,
        height: "100%",
        background: "var(--cupertino-system-background)",
        borderRight: "0.5px solid var(--cupertino-separator)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 8,
          height: 52,
          padding: "0 24px",
          fontSize: 17,
          fontWeight: 600,
          letterSpacing: -0.41,
        }}
      >
        {title ?? (
          <>
            <AppLogo size={22} />
            <span
              style={{
                whiteSpace: "nowrap",
                overflow: "hidden",
                textOverflow: "ellipsis",
              }}
            >
              TrueNAS Manager
            </span>
          </>
        )}
      </div>
      <div
        style={{
          padding: "4px 16px",
          display: "flex",
          flexDirection: "column",
          gap: 2,
        }}
      >
        {destinations.map((d, i) => {
          const selected = i === selectedIndex;
          return (
            <button
              key={d.label}
              type="button"
              onClick={() => onDestinationSelected?.(i)}
              style={{
                display: "flex",
                alignItems: "center",
                padding: 8,
                border: "none",
                borderRadius: 11,
                background: selected
                  ? "var(--cupertino-sidebar-selected)"
                  : "transparent",
                boxShadow: selected ? "0 1px 4px rgba(0,0,0,0.06)" : undefined,
                color: selected
                  ? "var(--cupertino-sidebar-selected-text)"
                  : "var(--cupertino-label)",
                fontWeight: selected ? 600 : 400,
                font: "inherit",
                fontSize: 17,
                textAlign: "left",
                cursor: "pointer",
              }}
            >
              <span style={{ paddingRight: 10 }}>
                <CupertinoIcon
                  icon={d.icon}
                  size={22}
                  color="var(--cupertino-primary)"
                />
              </span>
              <span style={{ fontWeight: selected ? 600 : 400 }}>
                {d.label}
              </span>
            </button>
          );
        })}
      </div>
    </aside>
  );
}

function useWidth<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const [width, setWidth] = useState<number | null>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver(([entry]) =>
      setWidth(entry.contentRect.width),
    );
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  return [ref, width] as const;
}

export interface AdaptiveNavigationScaffoldProps {
  /** The routed screen, usually a `CupertinoNavigationBar` plus content. */
  children: ReactNode;
  /** `compact` = bottom tab bar (phones); `expanded` = sidebar (tablets, desktop/macOS). `auto` picks by width at 768px. */
  layout?: "auto" | "compact" | "expanded";
  selectedIndex?: number;
  onDestinationSelected?: (index: number) => void;
  /** Sidebar visible in `expanded` layout. The floating toggle flips it. */
  defaultSidebarExpanded?: boolean;
}

/**
 * The app shell: below 768px a full-height screen over a bottom
 * `CupertinoTabBar`; at 768px and up (and always on macOS) a collapsible
 * `CupertinoSidebar` beside the screen on `systemGroupedBackground`, with a
 * floating sidebar toggle. Fills its parent's height.
 */
export function AdaptiveNavigationScaffold({
  children,
  layout = "auto",
  selectedIndex = 0,
  onDestinationSelected,
  defaultSidebarExpanded = true,
}: AdaptiveNavigationScaffoldProps) {
  const [ref, width] = useWidth<HTMLDivElement>();
  const [sidebarExpanded, setSidebarExpanded] = useState(
    defaultSidebarExpanded,
  );
  const expanded =
    layout === "expanded" ||
    (layout === "auto" && (width ?? 0) >= NAVIGATION_BREAKPOINT);

  return (
    <div
      ref={ref}
      style={{
        position: "relative",
        display: "flex",
        flexDirection: expanded ? "row" : "column",
        height: "100%",
        minHeight: 0,
        background: "var(--cupertino-system-background)",
        overflow: "hidden",
      }}
    >
      {expanded && sidebarExpanded && (
        <CupertinoSidebar
          selectedIndex={selectedIndex}
          onDestinationSelected={onDestinationSelected}
        />
      )}
      <main
        style={{
          flex: 1,
          minWidth: 0,
          minHeight: 0,
          overflow: "auto",
          background: expanded
            ? "var(--cupertino-system-grouped-background)"
            : undefined,
        }}
      >
        {children}
      </main>
      {!expanded && (
        <CupertinoTabBar
          currentIndex={selectedIndex}
          onTap={onDestinationSelected}
        />
      )}
      {expanded && (
        <button
          type="button"
          aria-label={sidebarExpanded ? "Hide sidebar" : "Show sidebar"}
          onClick={() => setSidebarExpanded((v) => !v)}
          className="cupertino-button"
          style={{
            position: "absolute",
            top: 8,
            left: sidebarExpanded ? 280 : 10,
            padding: 8,
            borderRadius: 8,
            border: "0.5px solid var(--cupertino-separator)",
            background:
              "color-mix(in srgb, var(--cupertino-system-background) 90%, transparent)",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
            cursor: "pointer",
            lineHeight: 0,
          }}
        >
          <CupertinoIcon
            icon={sidebarExpanded ? "sidebar_left" : "sidebar_right"}
            size={18}
            color="activeBlue"
          />
        </button>
      )}
    </div>
  );
}

export interface ShellBackButtonProps {
  /** Caption with the screen being returned to, e.g. "Servers". */
  previousPageTitle?: string;
  onClick?: () => void;
}

/** The nav-bar back chevron (with optional previous-page caption) used by server screens. */
export function ShellBackButton({
  previousPageTitle,
  onClick,
}: ShellBackButtonProps) {
  return (
    <button
      type="button"
      className="cupertino-button"
      onClick={onClick}
      style={{
        display: "inline-flex",
        alignItems: "center",
        marginLeft: -8,
        padding: 0,
        border: "none",
        background: "transparent",
        color: "var(--cupertino-primary)",
        font: "inherit",
        fontSize: 17,
        letterSpacing: -0.41,
        cursor: "pointer",
      }}
    >
      <CupertinoIcon icon="back" size={28} color="var(--cupertino-primary)" />
      {previousPageTitle}
    </button>
  );
}

export type DeviceKind = "phone" | "tablet" | "desktop";

const DEVICE_SIZES: Record<DeviceKind, [number, number]> = {
  phone: [390, 844],
  tablet: [820, 1180],
  desktop: [1280, 800],
};

export interface DeviceFrameProps {
  children: ReactNode;
  /** phone = iPhone 14 (390x844), tablet = iPad Air (820x1180), desktop = macOS window (1280x800). */
  device?: DeviceKind;
  /** Swaps width and height. Desktop defaults to landscape, others to portrait. */
  orientation?: "portrait" | "landscape";
  /** Force the palette inside the frame. Omit to follow the system. */
  brightness?: "light" | "dark";
  /** Scale the frame down for overview boards, e.g. 0.5. */
  scale?: number;
}

/**
 * A fixed-size viewport for laying out a whole screen at a target form
 * factor: phone, tablet or desktop, portrait or landscape, light or dark.
 * Content inside is rendered at real CSS pixels, then scaled.
 */
export function DeviceFrame({
  children,
  device = "phone",
  orientation,
  brightness,
  scale = 1,
}: DeviceFrameProps) {
  const [w0, h0] = DEVICE_SIZES[device];
  const landscape =
    (orientation ?? (device === "desktop" ? "landscape" : "portrait")) ===
    "landscape";
  const portraitNative = device !== "desktop";
  const [w, h] = landscape === portraitNative ? [h0, w0] : [w0, h0];
  const radius = device === "phone" ? 44 : device === "tablet" ? 20 : 10;
  const classes = ["cupertino-app"];
  if (brightness === "dark") classes.push("cupertino-dark");
  if (brightness === "light") classes.push("cupertino-light");
  return (
    <div style={{ width: w * scale, height: h * scale, flexShrink: 0 }}>
      <div
        className={classes.join(" ")}
        style={{
          width: w,
          height: h,
          // Always transformed: a transform makes this the containing block for
          // position: fixed descendants, so dialog barriers stay inside the frame.
          transform: `scale(${scale})`,
          transformOrigin: "top left",
          borderRadius: radius,
          overflow: "hidden",
          border: "1px solid var(--cupertino-opaque-separator)",
          boxShadow: "0 8px 30px rgba(0,0,0,0.12)",
          background: "var(--cupertino-system-background)",
          display: "flex",
          flexDirection: "column",
        }}
      >
        {device === "desktop" && (
          <div
            style={{
              height: 28,
              flexShrink: 0,
              display: "flex",
              alignItems: "center",
              gap: 8,
              padding: "0 12px",
              background: "var(--cupertino-secondary-system-background)",
              borderBottom: "0.5px solid var(--cupertino-separator)",
            }}
          >
            {["#FF5F57", "#FEBC2E", "#28C840"].map((c) => (
              <span
                key={c}
                style={{
                  width: 12,
                  height: 12,
                  borderRadius: "50%",
                  background: c,
                }}
              />
            ))}
          </div>
        )}
        <div
          style={{
            flex: 1,
            minHeight: 0,
            display: "flex",
            flexDirection: "column",
          }}
        >
          {children}
        </div>
      </div>
    </div>
  );
}
