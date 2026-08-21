#!/usr/bin/env bash
#===============================================================================
#   Author: Wenxuan
#    Email: wenxuangm@gmail.com
#  Created: 2018-04-05 17:37
#===============================================================================

# Defaults and user overrides

set_defaults() {
    right_arrow_icon=''
    left_arrow_icon=''
    prefix_highlight_pos=''

    # Section contents (left: outer→inner, right: inner→outer)
    left_a=' #{USER}@#h'
    left_b=' #S'
    left_c=''
    left_d=''
    right_w=''
    right_x=''
    right_y=' %T'
    right_z=' %F'

    # Section styles (spliced directly into tmux format strings)
    left_a_style='bold'
    left_b_style=''
    left_c_style=''
    left_d_style=''
    right_w_style=''
    right_x_style=''
    right_y_style=''
    right_z_style=''
    window_current_style='bold'
    window_last_style='bold'
    window_activity_style='bold'
    window_bell_style='bold'
    prefix_highlight_style='bold'
    theme='gold'

    # Fork options (ueoo/tmux-power)
    style='powerline'     # 'powerline' | 'text' (bare coloured text, no blocks)
    bg=''                 # fill: '' = g0, 'default'/'transparent' = terminal background
    gap='off'             # spacer row above the bar: 'off' | 'on' (blank) | 'line' (hairline)
    gap_line_color=''     # '' = auto (gray-teal in text style, g3 otherwise)
    # text-style palette: one foreground per section (left_a keeps the theme colour)
    text_left_a_color=''
    text_left_b_color='#b58900'
    text_left_c_color=''
    text_left_d_color=''
    text_right_w_color=''
    text_right_x_color=''
    text_right_y_color='#268bd2'
    text_right_z_color='#6c71c4'
    text_window_color='#657b83'
    text_current_color='#d33682'

    g0='#262626'
    g1='#303030'
    g2='#3a3a3a'
    g3='#444444'
    g4='#626262'
    status_interval='1'
}

# Theme resolution

resolve_theme_colors() {
    TC="$theme"
    case $TC in
        gold)       TC='#ffb86c' ;;
        redwine)    TC='#b34a47' ;;
        moon)       TC='#00abab' ;;
        forest)     TC='#228b22' ;;
        violet)     TC='#9370db' ;;
        snow)       TC='#fffafa' ;;
        coral)      TC='#ff7f50' ;;
        sky)        TC='#87ceeb' ;;
        everforest) TC='#a7c080' ;;
    esac

    G0="$g0"
    G1="$g1"
    G2="$g2"
    G3="$g3"
    G4="$g4"

    # Fill colour behind the bar. 'default' is the terminal background, which
    # only works as a style-string value (see configure_status_bar).
    case $bg in
        '' | none)             BG="$G0" ;;
        default | transparent) BG='default' ;;
        *)                     BG="$bg" ;;
    esac
    [[ $style_mode == 'text' ]] && BG='default'
}

# Status bar assembly

configure_status_bar() {
    tmux_set status-interval "$status_interval"
    tmux_set status on

    # Legacy status-fg/bg are unset first: a server that once ran an older
    # version keeps them, and on tmux >= 3.6 a stale status-bg overrides the
    # style's bg=default at render time. To the legacy options 'default'
    # means reset-to-tmux-default (black on green), so only style strings
    # can express a transparent fill.
    tmux_unset status-bg
    tmux_unset status-fg
    tmux_set status-style "fg=$G4,bg=$BG"

    tmux_set @prefix_highlight_show_copy_mode 'on'
    tmux_set @prefix_highlight_copy_mode_attr "fg=$TC,bg=$BG,$prefix_highlight_style"
    tmux_set @prefix_highlight_output_prefix "#[fg=$TC]#[bg=$BG]$left_arrow_icon#[bg=$TC]#[fg=$G0]"
    tmux_set @prefix_highlight_output_suffix "#[fg=$TC]#[bg=$BG]$right_arrow_icon"

    tmux_unset status-left-bg
    tmux_unset status-right-bg
    tmux_set status-left-style "fg=$G4,bg=$BG"
    tmux_set status-left-length 150
    tmux_set status-right-style "fg=$G4,bg=$BG"
    tmux_set status-right-length 150
}

build_left_status() {
    local LS="" prev_bg="$BG" first=true
    local content bg fg style i
    local -a left_bgs=("$TC" "$G2" "$G1" "$G1")
    local -a left_fgs=("$G0" "$TC" "$TC" "$TC")
    local -a left_contents=("$left_a" "$left_b" "$left_c" "$left_d")
    local -a left_styles_arr=("$left_a_style" "$left_b_style" "$left_c_style" "$left_d_style")
    local -a left_text_colors=("${text_left_a_color:-$TC}" "${text_left_b_color:-$TC}" "${text_left_c_color:-$TC}" "${text_left_d_color:-$TC}")

    for i in "${!left_contents[@]}"; do
        content="${left_contents[$i]}"
        [[ -z "$content" ]] && continue
        style="${left_styles_arr[$i]:+,${left_styles_arr[$i]}}"

        if [[ $style_mode == 'text' ]]; then
            # bare coloured text: no blocks, no arrows
            LS+="#[fg=${left_text_colors[$i]},bg=default${style}] $content "
            continue
        fi

        bg="${left_bgs[$i]}"
        fg="${left_fgs[$i]}"
        if "$first"; then
            LS="#[fg=$fg,bg=$bg${style}] $content "
            first=false
        else
            LS+="#[fg=$prev_bg,bg=$bg,none]$right_arrow_icon"
            LS+="#[fg=$fg,bg=$bg${style}] $content "
        fi
        prev_bg="$bg"
    done

    [[ -n "$LS" && $style_mode != 'text' ]] && LS+="#[fg=$prev_bg,bg=$BG,none]$right_arrow_icon"

    if [[ $prefix_highlight_pos == 'L' || $prefix_highlight_pos == 'LR' ]]; then
        LS="$LS#{prefix_highlight}"
    fi

    tmux_set status-left "$LS"
}

build_right_status() {
    local RS="" prev_bg="$BG"
    local content bg fg style i
    local -a right_bgs=("$G1" "$G1" "$G2" "$TC")
    local -a right_fgs=("$TC" "$TC" "$TC" "$G0")
    local -a right_contents=("$right_w" "$right_x" "$right_y" "$right_z")
    local -a right_styles_arr=("$right_w_style" "$right_x_style" "$right_y_style" "$right_z_style")
    local -a right_text_colors=("${text_right_w_color:-$TC}" "${text_right_x_color:-$TC}" "${text_right_y_color:-$TC}" "${text_right_z_color:-$TC}")

    for i in "${!right_contents[@]}"; do
        content="${right_contents[$i]}"
        [[ -z "$content" ]] && continue
        style="${right_styles_arr[$i]:+,${right_styles_arr[$i]}}"

        if [[ $style_mode == 'text' ]]; then
            RS+="#[fg=${right_text_colors[$i]},bg=default${style}] $content "
            continue
        fi

        bg="${right_bgs[$i]}"
        fg="${right_fgs[$i]}"
        RS+="#[fg=$bg,bg=$prev_bg,none]$left_arrow_icon"
        RS+="#[fg=$fg,bg=$bg${style}] $content "
        prev_bg="$bg"
    done

    if [[ $prefix_highlight_pos == 'R' || $prefix_highlight_pos == 'LR' ]]; then
        RS="#{prefix_highlight}$RS"
    fi

    tmux_set status-right "$RS"
}

# Window, pane, and message styles

configure_ui_styles() {
    if [[ $style_mode == 'text' ]]; then
        tmux_set window-status-format         "#[fg=$text_window_color,bg=default] #I:#W#F "
        tmux_set window-status-current-format "#[fg=$text_current_color,bg=default,$window_current_style] #I:#W#F "
    elif [[ $BG == 'default' ]]; then
        # transparent fill: the fill colour cannot be an arrow foreground, so
        # segments get outward-pointing caps on both sides
        tmux_set window-status-format         "#[fg=$G2,bg=default]$left_arrow_icon#[fg=$TC,bg=$G2] #I:#W#F #[fg=$G2,bg=default]$right_arrow_icon"
        tmux_set window-status-current-format "#[fg=$TC,bg=default]$left_arrow_icon#[fg=$G0,bg=$TC,$window_current_style] #I:#W#F #[fg=$TC,bg=default,none]$right_arrow_icon"
    else
        tmux_set window-status-format         "#[fg=$G0,bg=$G2]$right_arrow_icon#[fg=$TC,bg=$G2] #I:#W#F #[fg=$G2,bg=$G0]$right_arrow_icon"
        tmux_set window-status-current-format "#[fg=$G0,bg=$TC]$right_arrow_icon#[fg=$G0,bg=$TC,$window_current_style] #I:#W#F #[fg=$TC,bg=$G0,none]$right_arrow_icon"
    fi

    tmux_set window-status-style          "fg=$TC,bg=$BG,none"
    tmux_set window-status-last-style     "fg=$TC,bg=$BG,$window_last_style"
    tmux_set window-status-activity-style "fg=$TC,bg=$BG,$window_activity_style"
    tmux_set window-status-bell-style     "fg=$TC,bg=$BG,$window_bell_style"
    tmux_set window-status-separator ""

    tmux_set pane-border-style "fg=$G3,bg=default"
    tmux_set pane-active-border-style "fg=$TC,bg=default"

    tmux_set display-panes-colour "$G3"
    tmux_set display-panes-active-colour "$TC"

    tmux_set clock-mode-colour "$TC"
    tmux_set clock-mode-style 24

    tmux_set message-style "fg=$TC,bg=$BG"
    tmux_set message-command-style "fg=$TC,bg=$BG"
    tmux_set mode-style "bg=$TC,fg=$G4"
}

# Spacer row between the panes and the bar (fork feature)

configure_gap() {
    case $gap in
        on | true | line) ;;
        *)
            tmux_unset status-format
            tmux_unset message-line
            return
            ;;
    esac

    # The bar keeps tmux's own compiled status-format, moved to row 1, so the
    # window list renders exactly as on a single-row status line on every
    # tmux version. The default is only readable when the whole array is
    # unset, and that must happen before the read, outside the batch.
    tmux set-option -gqu status-format
    local default_format
    default_format="$(tmux show-options -gv 'status-format[0]')"
    tmux_set 'status-format[1]' "$default_format"

    if [[ $gap == 'line' ]]; then
        local color="$gap_line_color"
        if [[ -z $color ]]; then
            [[ $style_mode == 'text' ]] && color='#586e75' || color="$G3"
        fi
        # a long run of box-drawing characters, clipped to the window width
        tmux_set 'status-format[0]' "#[fg=$color,bg=default]$(printf '─%.0s' {1..600})"
    else
        tmux_set 'status-format[0]' ''
    fi
    tmux_set status 2
    # messages and the command prompt use row 0 (tmux's default): they show
    # in the gap and never hide the bar
    tmux_unset message-line
}

# Batch write: accumulate set-option commands, flush at end
_tmux_set_cmds=""

# $1: option (queued as an unset, in order with the sets)
tmux_unset() {
    _tmux_set_cmds+="set-option -gqu \"$1\""$'\n'
}

# $1: option
# $2: value
tmux_set() {
    local _escaped _value="$2"

    if [[ $_value == *"'"* ]]; then
        _escaped="${_value//\\/\\\\}"   # `a\b` -> `a\\b` so literal backslashes survive tmux double quotes
        _escaped="${_escaped//\$/\\\$}" # `$PWD` -> `\$PWD` so shell variables stay literal in tmux command formats
        _escaped="${_escaped//\"/\\\"}" # `"hi"` -> `\"hi\"` so embedded double quotes do not end the tmux string
        _escaped="${_escaped//\`/\\\`}" # keep backticks literal so tmux does not treat them as command substitution
        _tmux_set_cmds+="set-option -gq \"$1\" \"$_escaped\""$'\n'
    else
        _tmux_set_cmds+="set-option -gq \"$1\" '$_value'"$'\n'
    fi
}

# Flush all accumulated set-option commands at once (single fork)
tmux_flush() {
    [[ -z "$_tmux_set_cmds" ]] && return
    # tmux 3.0+ supports reading from stdin via 'source-file -'
    if ! tmux source-file - <<<"$_tmux_set_cmds" 2>/dev/null; then
        local _tmpfile
        _tmpfile="$(mktemp)"
        printf '%s' "$_tmux_set_cmds" >"$_tmpfile"
        tmux source-file "$_tmpfile"
        rm -f "$_tmpfile"
    fi
}

# Batch-read all @tmux_power_* options in one tmux call, but escape shell-active
# characters before feeding the assignments back to eval. tmux show -g serializes
# values with shell-style quoting (including single-quoted forms), so the awk
# pass only escapes $ and ` outside single quotes to preserve tmux/status-format
# literals like #{user}, #(cmd), and $(...) without giving up the PR #62 fast path.
load_tmux_options() {
    eval "$(
        tmux show -g | awk '
            BEGIN {
                sq = sprintf("%c", 39)
                dq = "\""
                bt = sprintf("%c", 96)
                bs = "\\"
            }

            /^@tmux_power_[A-Za-z_][A-Za-z0-9_]* / {
                line = $0
                sub(/^@tmux_power_/, "", line)

                key = line
                sub(/ .*/, "", key)
                sub(/^[^ ]+ /, "", line)

                rhs = line
                n = length(rhs)
                out = ""
                in_sq = 0
                in_dq = 0

                for (i = 1; i <= n; i++) {
                    ch = substr(rhs, i, 1)

                    if (in_sq) {
                        out = out ch
                        if (ch == sq)
                            in_sq = 0
                        continue
                    }

                    # tmux show -g may serialize a literal $ as \$, \\$,
                    # \\\\\\$, etc. depending on the version. Collapse any
                    # run of 1+ backslashes before $ or ` into exactly one.
                    if (ch == bs) {
                        j = i
                        while (j < n && substr(rhs, j + 1, 1) == bs)
                            j++

                        if (j < n) {
                            next_ch = substr(rhs, j + 1, 1)
                            if (next_ch == "$" || next_ch == bt) {
                                out = out bs next_ch
                                i = j + 1
                                continue
                            }
                        }
                    }

                    if (ch == bs) {
                        out = out ch
                        i++
                        if (i <= n)
                            out = out substr(rhs, i, 1)
                        continue
                    }

                    if (ch == sq && !in_dq) {
                        in_sq = 1
                        out = out ch
                        continue
                    }

                    if (ch == dq) {
                        in_dq = !in_dq
                        out = out ch
                        continue
                    }

                    if (ch == "$" || ch == bt)
                        out = out bs ch
                    else
                        out = out ch
                }

                print key "=" out
            }
        '
    )"
}

main() {
    set_defaults
    load_tmux_options
    # 'style' is also a per-section option suffix; keep the mode in its own name
    style_mode="$style"
    [[ $style_mode == 'plain' ]] && style_mode='text'
    resolve_theme_colors
    configure_status_bar
    build_left_status
    build_right_status
    configure_ui_styles
    configure_gap
    tmux_flush
}

main "$@"
