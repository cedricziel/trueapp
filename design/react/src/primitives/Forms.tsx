import { Children, type CSSProperties, type ReactNode } from "react";
import { CupertinoIcon } from "./CupertinoIcon";

export interface CupertinoPageScaffoldProps {
  /** Usually a `CupertinoNavigationBar`. */
  navigationBar?: ReactNode;
  children?: ReactNode;
  /** `systemGroupedBackground` behind form screens (settings, add/edit server). Defaults to `systemBackground`. */
  background?: "systemBackground" | "systemGroupedBackground";
}

/** Flutter's `CupertinoPageScaffold`: a nav bar over a scrolling page body. Fills its parent's height. */
export function CupertinoPageScaffold({
  navigationBar,
  children,
  background = "systemBackground",
}: CupertinoPageScaffoldProps) {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        height: "100%",
        minHeight: 0,
        background:
          background === "systemGroupedBackground"
            ? "var(--cupertino-system-grouped-background)"
            : "var(--cupertino-system-background)",
      }}
    >
      {navigationBar}
      <div style={{ flex: 1, minHeight: 0, overflow: "auto" }}>{children}</div>
    </div>
  );
}

export interface CupertinoFormSectionProps {
  /** Small grey caption above the rows, conventionally uppercase ("SECURITY"). */
  header?: ReactNode;
  /** Small grey caption below the rows. */
  footer?: ReactNode;
  /** Rows, usually `CupertinoFormRow` / `CupertinoTextFormFieldRow`. Hairline dividers go between them. */
  children: ReactNode;
  /** iOS inset-grouped look (rounded, 20px side margins). Defaults to false - the app uses full-width sections. */
  insetGrouped?: boolean;
}

/**
 * Flutter's `CupertinoFormSection`: a group of settings/form rows on the
 * grouped background, with a caption header, hairline dividers inset 20px,
 * and an optional footer.
 */
export function CupertinoFormSection({
  header,
  footer,
  children,
  insetGrouped = false,
}: CupertinoFormSectionProps) {
  const rows = Children.toArray(children);
  const caption: CSSProperties = {
    fontSize: 13,
    letterSpacing: -0.08,
    color: "var(--cupertino-secondary-label)",
  };
  return (
    <section style={{ paddingTop: header ? 0 : 22 }}>
      {header && (
        <div
          style={{
            ...caption,
            padding: "22px 20px 6px",
            textTransform: "uppercase",
          }}
        >
          {header}
        </div>
      )}
      <div
        style={{
          margin: insetGrouped ? "0 20px" : 0,
          borderRadius: insetGrouped ? 10 : 0,
          overflow: "hidden",
          background: "var(--cupertino-secondary-system-grouped-background)",
          borderTop: insetGrouped
            ? undefined
            : "0.5px solid var(--cupertino-separator)",
          borderBottom: insetGrouped
            ? undefined
            : "0.5px solid var(--cupertino-separator)",
        }}
      >
        {rows.map((row, i) => (
          <div key={i} style={{ position: "relative" }}>
            {i > 0 && (
              <div
                style={{
                  position: "absolute",
                  top: 0,
                  left: 20,
                  right: 0,
                  borderTop: "0.5px solid var(--cupertino-separator)",
                }}
              />
            )}
            {row}
          </div>
        ))}
      </div>
      {footer && (
        <div style={{ ...caption, padding: "6px 20px 0" }}>{footer}</div>
      )}
    </section>
  );
}

export interface CupertinoFormRowProps {
  /** Leading label, e.g. "Server Name", or a `FormRowLabel` (title + subtitle). */
  prefix?: ReactNode;
  /** Trailing control or value, right-aligned: a `CupertinoSwitch`, a value string, a chevron. */
  children?: ReactNode;
  /** Grey helper text under the row. */
  helper?: ReactNode;
  /** Red validation message under the row. */
  error?: ReactNode;
  onClick?: () => void;
}

/** Flutter's `CupertinoFormRow`: a 44px-min row with a leading prefix and a trailing control. */
export function CupertinoFormRow({
  prefix,
  children,
  helper,
  error,
  onClick,
}: CupertinoFormRowProps) {
  return (
    <div
      onClick={onClick}
      style={{
        padding: "6px 6px 6px 20px",
        minHeight: 44,
        cursor: onClick ? "pointer" : undefined,
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 12,
          minHeight: 32,
        }}
      >
        {prefix != null && (
          <div style={{ display: "flex", minWidth: 0 }}>{prefix}</div>
        )}
        <div
          style={{
            flex: "0 1 auto",
            minWidth: 0,
            display: "flex",
            justifyContent: "flex-end",
            alignItems: "center",
            gap: 6,
            paddingRight: 10,
            color: "var(--cupertino-secondary-label)",
          }}
        >
          {children}
        </div>
      </div>
      {helper && (
        <div
          style={{ fontSize: 13, color: "var(--cupertino-secondary-label)" }}
        >
          {helper}
        </div>
      )}
      {error && (
        <div
          style={{
            fontSize: 13,
            fontWeight: 500,
            color: "var(--cupertino-system-red)",
          }}
        >
          {error}
        </div>
      )}
    </div>
  );
}

const inputReset: CSSProperties = {
  flex: 1,
  minWidth: 0,
  border: "none",
  outline: "none",
  background: "transparent",
  font: "inherit",
  fontSize: 17,
  letterSpacing: -0.41,
  color: "var(--cupertino-label)",
  padding: 0,
};

export interface CupertinoTextFormFieldRowProps {
  /** Leading label, e.g. "Host". */
  prefix?: ReactNode;
  placeholder?: string;
  value?: string;
  /** Password field. */
  obscureText?: boolean;
  /** Red validation message under the row. */
  error?: string;
  onChange?: (value: string) => void;
}

/** Flutter's `CupertinoTextFormFieldRow`: a borderless text input inside a form section, with an optional leading label. */
export function CupertinoTextFormFieldRow({
  prefix,
  placeholder,
  value,
  obscureText,
  error,
  onChange,
}: CupertinoTextFormFieldRowProps) {
  return (
    <div style={{ padding: "6px 6px 6px 20px", minHeight: 44 }}>
      <label
        style={{
          display: "flex",
          alignItems: "center",
          gap: 12,
          minHeight: 32,
        }}
      >
        {prefix != null && <span style={{ flexShrink: 0 }}>{prefix}</span>}
        <input
          type={obscureText ? "password" : "text"}
          placeholder={placeholder}
          value={value}
          readOnly={onChange == null}
          onChange={(e) => onChange?.(e.target.value)}
          style={{ ...inputReset, padding: "6px 0" }}
        />
      </label>
      {error && (
        <div
          style={{
            fontSize: 13,
            fontWeight: 500,
            color: "var(--cupertino-system-red)",
          }}
        >
          {error}
        </div>
      )}
    </div>
  );
}

export interface CupertinoTextFieldProps {
  placeholder?: string;
  value?: string;
  obscureText?: boolean;
  /** Leading content inside the field, e.g. an icon. */
  prefix?: ReactNode;
  /** Monospace input, for API keys and paths. */
  monospace?: boolean;
  onChange?: (value: string) => void;
  style?: CSSProperties;
}

/** Flutter's `CupertinoTextField`: a standalone bordered, rounded text input. */
export function CupertinoTextField({
  placeholder,
  value,
  obscureText,
  prefix,
  monospace,
  onChange,
  style,
}: CupertinoTextFieldProps) {
  return (
    <label
      style={{
        display: "flex",
        alignItems: "center",
        gap: 6,
        padding: "7px 7px",
        borderRadius: 5,
        border: "0.5px solid var(--cupertino-system-grey4)",
        background: "var(--cupertino-system-background)",
        ...style,
      }}
    >
      {prefix}
      <input
        type={obscureText ? "password" : "text"}
        placeholder={placeholder}
        value={value}
        readOnly={onChange == null}
        onChange={(e) => onChange?.(e.target.value)}
        style={{
          ...inputReset,
          fontFamily: monospace ? "var(--cupertino-font-mono)" : "inherit",
        }}
      />
    </label>
  );
}

export interface CupertinoSearchTextFieldProps {
  placeholder?: string;
  value?: string;
  onChange?: (value: string) => void;
}

/** Flutter's `CupertinoSearchTextField`: the grey 9px-radius search pill with a magnifier. */
export function CupertinoSearchTextField({
  placeholder = "Search",
  value,
  onChange,
}: CupertinoSearchTextFieldProps) {
  return (
    <label
      style={{
        display: "flex",
        alignItems: "center",
        gap: 6,
        padding: "8px 5px 8px 6px",
        borderRadius: 9,
        background: "var(--cupertino-tertiary-system-fill)",
        color: "var(--cupertino-secondary-label)",
      }}
    >
      <CupertinoIcon icon="search" size={20} color="secondaryLabel" />
      <input
        type="search"
        placeholder={placeholder}
        value={value}
        readOnly={onChange == null}
        onChange={(e) => onChange?.(e.target.value)}
        style={inputReset}
      />
    </label>
  );
}

export interface CupertinoSwitchProps {
  value: boolean;
  onChange?: (value: boolean) => void;
  disabled?: boolean;
}

/** Flutter's `CupertinoSwitch`: the 51x31 iOS toggle, green when on. */
export function CupertinoSwitch({
  value,
  onChange,
  disabled = false,
}: CupertinoSwitchProps) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={value}
      disabled={disabled}
      onClick={() => onChange?.(!value)}
      style={{
        position: "relative",
        width: 51,
        height: 31,
        flexShrink: 0,
        padding: 0,
        border: "none",
        borderRadius: 16,
        background: value
          ? "var(--cupertino-system-green)"
          : "var(--cupertino-secondary-system-fill)",
        opacity: disabled ? 0.5 : 1,
        cursor: disabled ? "default" : "pointer",
        transition: "background 0.2s ease",
      }}
    >
      <span
        style={{
          position: "absolute",
          top: 2,
          left: value ? 22 : 2,
          width: 27,
          height: 27,
          borderRadius: "50%",
          background: "#fff",
          boxShadow: "0 3px 8px rgba(0,0,0,0.15), 0 3px 1px rgba(0,0,0,0.06)",
          transition: "left 0.2s ease",
        }}
      />
    </button>
  );
}

export interface CupertinoActionSheetActionProps {
  children: ReactNode;
  isDefaultAction?: boolean;
  isDestructiveAction?: boolean;
  onClick?: () => void;
}

/** Flutter's `CupertinoActionSheetAction`: one 57px row in a `CupertinoActionSheet`. */
export function CupertinoActionSheetAction({
  children,
  isDefaultAction,
  isDestructiveAction,
  onClick,
}: CupertinoActionSheetActionProps) {
  return (
    <button
      type="button"
      className="cupertino-button"
      onClick={onClick}
      style={{
        width: "100%",
        minHeight: 57,
        padding: "16px 10px",
        border: "none",
        background: "transparent",
        font: "inherit",
        fontSize: 20,
        letterSpacing: 0.38,
        fontWeight: isDefaultAction ? 600 : 400,
        color: isDestructiveAction
          ? "var(--cupertino-system-red)"
          : "var(--cupertino-system-blue)",
        cursor: "pointer",
      }}
    >
      {children}
    </button>
  );
}

export interface CupertinoActionSheetProps {
  title?: ReactNode;
  message?: ReactNode;
  /** `CupertinoActionSheetAction`s. */
  actions: ReactNode[];
  /** Separate bottom button, conventionally "Cancel". */
  cancelButton?: ReactNode;
}

/**
 * Flutter's `CupertinoActionSheet` (shown via `showCupertinoModalPopup`): a
 * bottom sheet of stacked actions with an optional title/message and a
 * separate Cancel button. Renders inline; place it at the bottom of a screen.
 */
export function CupertinoActionSheet({
  title,
  message,
  actions,
  cancelButton,
}: CupertinoActionSheetProps) {
  const group: CSSProperties = {
    borderRadius: 14,
    overflow: "hidden",
    background:
      "color-mix(in srgb, var(--cupertino-secondary-system-grouped-background) 92%, transparent)",
    backdropFilter: "blur(20px)",
  };
  const divider = "0.5px solid var(--cupertino-separator)";
  return (
    <div
      style={{
        padding: "0 8px 8px",
        display: "flex",
        flexDirection: "column",
        gap: 8,
        textAlign: "center",
      }}
    >
      <div style={group}>
        {(title || message) && (
          <div
            style={{
              padding: "14px 16px",
              color: "var(--cupertino-secondary-label)",
              fontSize: 13,
            }}
          >
            {title && <div style={{ fontWeight: 600 }}>{title}</div>}
            {message && (
              <div style={{ marginTop: title ? 4 : 0 }}>{message}</div>
            )}
          </div>
        )}
        {actions.map((a, i) => (
          <div
            key={i}
            style={{
              borderTop: i > 0 || title || message ? divider : undefined,
            }}
          >
            {a}
          </div>
        ))}
      </div>
      {cancelButton && <div style={group}>{cancelButton}</div>}
    </div>
  );
}
