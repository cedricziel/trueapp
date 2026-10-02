import { useId, type CSSProperties } from "react";
import {
  Archive,
  ArrowDown,
  ArrowDownWideNarrow,
  ArrowUpRight,
  Box,
  ChartPie,
  Check,
  CirclePause,
  CirclePlay,
  CircleUser,
  Cog,
  Ellipsis,
  File,
  FileText,
  Film,
  Folder,
  Image,
  Info,
  LayoutGrid,
  Link,
  Minus,
  Music,
  Package,
  Pencil,
  Plus,
  Search,
  SquareDot,
  User,
  X,
  ArrowUp,
  AudioWaveform,
  Bell,
  Camera,
  ChartColumn,
  ChevronDown,
  ChevronLeft,
  PanelLeftClose,
  PanelLeftOpen,
  ChevronRight,
  ChevronUp,
  Circle,
  CircleAlert,
  CircleArrowDown,
  CircleArrowUp,
  CircleCheck,
  CircleHelp,
  Clock,
  CloudUpload,
  Gauge,
  Globe,
  Heart,
  House,
  Layers,
  Lock,
  LockKeyholeOpen,
  LockOpen,
  MemoryStick,
  MessageSquareWarning,
  Monitor,
  RefreshCcw,
  RefreshCw,
  RotateCw,
  Settings,
  Shield,
  ShieldAlert,
  ShieldCheck,
  Square,
  Star,
  Tag,
  Trash2,
  Wifi,
  WifiOff,
  type LucideIcon,
} from "lucide-react";
import { resolveColor, type ColorValue } from "../colors";

const outlined = {
  add: Plus,
  app: Square,
  app_badge: SquareDot,
  archivebox: Archive,
  arrow_up_right: ArrowUpRight,
  chart_pie: ChartPie,
  checkmark: Check,
  checkmark_shield_fill: ShieldCheck,
  clock: Clock,
  cube: Box,
  cube_box: Package,
  doc_text_fill: FileText,
  ellipsis: Ellipsis,
  folder: Folder,
  gear_alt: Cog,
  info_circle: Info,
  link: Link,
  lock_shield_fill: ShieldCheck,
  minus: Minus,
  music_note: Music,
  pause_circle: CirclePause,
  pencil: Pencil,
  person_circle: CircleUser,
  photo: Image,
  photo_fill: Image,
  film_fill: Film,
  play_circle: CirclePlay,
  search: Search,
  sort_down: ArrowDownWideNarrow,
  square_grid_2x2: LayoutGrid,
  xmark: X,
  arrow_2_circlepath: RefreshCcw,
  arrow_clockwise: RotateCw,
  arrow_down: ArrowDown,
  arrow_down_circle: CircleArrowDown,
  arrow_up: ArrowUp,
  arrow_up_circle: CircleArrowUp,
  bell: Bell,
  camera: Camera,
  chart_bar: ChartColumn,
  checkmark_circle: CircleCheck,
  back: ChevronLeft,
  chevron_down: ChevronDown,
  house: House,
  settings: Settings,
  sidebar_left: PanelLeftClose,
  sidebar_right: PanelLeftOpen,
  chevron_right: ChevronRight,
  chevron_up: ChevronUp,
  circle: Circle,
  cloud_upload: CloudUpload,
  delete: Trash2,
  desktopcomputer: Monitor,
  device_desktop: Monitor,
  exclamationmark_bubble: MessageSquareWarning,
  exclamationmark_circle: CircleAlert,
  exclamationmark_shield: ShieldAlert,
  gear: Settings,
  globe: Globe,
  heart: Heart,
  lock: Lock,
  lock_open: LockOpen,
  lock_shield: ShieldCheck,
  lock_slash: LockKeyholeOpen,
  memories: MemoryStick,
  question_circle: CircleHelp,
  refresh: RefreshCw,
  shield: Shield,
  speedometer: Gauge,
  square_stack_3d_down_right: Layers,
  tag: Tag,
  time: Clock,
  waveform_path: AudioWaveform,
  wifi: Wifi,
  wifi_slash: WifiOff,
} satisfies Record<string, LucideIcon>;

const filledShapes = {
  heart_fill: Heart,
  star_fill: Star,
  house_fill: House,
  doc_fill: File,
  folder_fill: Folder,
  person_fill: User,
} satisfies Record<string, LucideIcon>;

/** Glyphs drawn in white on a solid disc, like the SF `*.circle.fill` symbols. */
const circleGlyphs = {
  checkmark_circle_fill: "M7.5 12.5l3 3 6-6.5",
  xmark_circle_fill: "M8.5 8.5l7 7M15.5 8.5l-7 7",
  minus_circle_fill: "M7.5 12h9",
  exclamationmark_circle_fill: "M12 7v6M12 16.6v.1",
  arrow_up_circle_fill: "M12 17V7.5M8 11.5l4-4 4 4",
} as const;

export type CupertinoIconName =
  | keyof typeof outlined
  | keyof typeof filledShapes
  | keyof typeof circleGlyphs
  | "exclamationmark"
  | "wifi_exclamationmark"
  | "exclamationmark_triangle"
  | "exclamationmark_triangle_fill";

export interface CupertinoIconProps {
  /** A `CupertinoIcons.*` name as used in the Flutter app, e.g. `"bell"`. */
  icon: CupertinoIconName;
  /** A `CupertinoColors` name or CSS color. Defaults to the current text color. */
  color?: ColorValue;
  /** Glyph size in px (Flutter's `Icon.size`). Defaults to 24. */
  size?: number;
  style?: CSSProperties;
}

const TRIANGLE =
  "M10.3 3.9 2.4 17.6A2 2 0 0 0 4.1 20.6h15.8a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0z";

/**
 * Flutter's `Icon(CupertinoIcons.x)`. Renders a line-icon equivalent of the
 * SF-style Cupertino glyph, in `color` at `size` px.
 */
export function CupertinoIcon({
  icon,
  color,
  size = 24,
  style,
}: CupertinoIconProps) {
  const stroke = color ? resolveColor(color) : "currentColor";
  const base: CSSProperties = { display: "block", flexShrink: 0, ...style };
  // Filled glyphs cut their inner mark out of the shape (SF Symbols style),
  // so it shows whatever is behind the icon in light and dark alike.
  const maskId = useId();

  if (icon in circleGlyphs) {
    return (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        style={base}
        aria-hidden
      >
        <mask id={maskId}>
          <circle cx="12" cy="12" r="10.5" fill="#fff" />
          <path
            d={circleGlyphs[icon as keyof typeof circleGlyphs]}
            fill="none"
            stroke="#000"
            strokeWidth="2.2"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </mask>
        <circle cx="12" cy="12" r="10.5" fill={stroke} mask={`url(#${maskId})`} />
      </svg>
    );
  }

  if (icon === "wifi_exclamationmark") {
    return (
      <svg
        width={size}
        height={size}
        viewBox="0 0 28 24"
        style={base}
        aria-hidden
      >
        <g
          fill="none"
          stroke={stroke}
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M12 20h.01M2 8.82a15 15 0 0 1 20 0M5 12.86a10 10 0 0 1 14 0M8.5 16.43a5 5 0 0 1 7 0" />
          <path d="M26 6v8M26 18.5v.1" strokeWidth="2.4" />
        </g>
      </svg>
    );
  }

  if (icon === "exclamationmark") {
    return (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        style={base}
        aria-hidden
      >
        <path
          d="M12 4v11M12 19.5v.1"
          stroke={stroke}
          strokeWidth="2.6"
          strokeLinecap="round"
        />
      </svg>
    );
  }

  if (
    icon === "exclamationmark_triangle" ||
    icon === "exclamationmark_triangle_fill"
  ) {
    const filled = icon === "exclamationmark_triangle_fill";
    return (
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        style={base}
        aria-hidden
      >
        {filled && (
          <mask id={maskId}>
            <path d={TRIANGLE} fill="#fff" stroke="#fff" strokeWidth="2" strokeLinejoin="round" />
            <path d="M12 9.5v4M12 17v.1" stroke="#000" strokeWidth="2.2" strokeLinecap="round" />
          </mask>
        )}
        <path
          d={TRIANGLE}
          fill={filled ? stroke : "none"}
          stroke={stroke}
          strokeWidth="2"
          strokeLinejoin="round"
          mask={filled ? `url(#${maskId})` : undefined}
        />
        {!filled && (
          <path d="M12 9.5v4M12 17v.1" stroke={stroke} strokeWidth="2.2" strokeLinecap="round" />
        )}
      </svg>
    );
  }

  if (icon in filledShapes) {
    const Glyph = filledShapes[icon as keyof typeof filledShapes];
    return (
      <Glyph
        size={size}
        color={stroke}
        fill={stroke}
        style={base}
        aria-hidden
      />
    );
  }

  const Glyph = outlined[icon as keyof typeof outlined];
  return (
    <Glyph
      size={size}
      color={stroke}
      strokeWidth={2}
      style={base}
      aria-hidden
    />
  );
}
