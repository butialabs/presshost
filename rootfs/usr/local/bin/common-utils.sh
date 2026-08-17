#!/bin/bash

if [[ "${COMMON_UTILS_LOADED:-}" == "true" ]]; then
    return 0
fi

COMMON_UTILS_LOADED="true"
declare -xr RED='\033[0;31m'
declare -xr GREEN='\033[0;32m'
declare -xr YELLOW='\033[1;33m'
declare -xr BLUE='\033[0;34m'
declare -xr PURPLE='\033[0;35m'
declare -xr CYAN='\033[0;36m'
declare -xr WHITE='\033[1;37m'
declare -xr NC='\033[0m'

readonly PRESSHOST_NEWT_ERROR='root=white,black;window=white,red;border=white,red;title=white,red;textbox=white,red;button=black,white;actbutton=white,red;actsellistbox=white,red;'
readonly PRESSHOST_NEWT_WARNING='root=white,black;window=black,yellow;border=black,yellow;title=black,yellow;textbox=black,yellow;button=black,white;actbutton=black,yellow;actsellistbox=black,yellow;'
readonly PRESSHOST_NEWT_INFO='root=white,black;window=white,blue;border=white,blue;title=white,blue;textbox=white,blue;button=black,white;actbutton=white,blue;actsellistbox=white,blue;'
readonly PRESSHOST_NEWT_SUCCESS='root=white,black;window=black,green;border=black,green;title=black,green;textbox=black,green;button=black,white;actbutton=black,green;actsellistbox=black,green;'

SCRIPT_NAME="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[1]}" .sh | tr '[:lower:]' '[:upper:]')}"

readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4
readonly LOG_LEVEL_TRACE=5

_resolve_log_level() {
    local raw="${LOG_LEVEL:-WARN}"
    case "${raw^^}" in
        ERROR|ERR|CRITICAL|CRIT|FATAL|0|1) echo "$LOG_LEVEL_ERROR" ;;
        WARN|WARNING|2)                    echo "$LOG_LEVEL_WARN" ;;
        INFO|NOTICE|3)                     echo "$LOG_LEVEL_INFO" ;;
        DEBUG|4)                           echo "$LOG_LEVEL_DEBUG" ;;
        TRACE|VERBOSE|5)                   echo "$LOG_LEVEL_TRACE" ;;
        *)                                 echo "$LOG_LEVEL_WARN" ;;
    esac
}

_log_enabled() {
    local required="$1"
    local current
    current=$(_resolve_log_level)
    (( current >= required ))
}

_format_message() {
    local level="$1"
    local message="$2"
    local color="$3"
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} ${level}:${NC} ${message}"
}

critical() {
    _log_enabled "$LOG_LEVEL_ERROR" || return 0
    echo -e "\033[41m\033[1;37m[$(date +'%Y-%m-%d %H:%M:%S')] ${SCRIPT_NAME} CRITICAL: ${1}${NC}" >&2
}

error() {
    _log_enabled "$LOG_LEVEL_ERROR" || return 0
    _format_message "ERROR" "$1" "$RED" >&2
}

warning() {
    _log_enabled "$LOG_LEVEL_WARN" || return 0
    _format_message "WARNING" "$1" "$YELLOW"
}

info() {
    _log_enabled "$LOG_LEVEL_INFO" || return 0
    _format_message "INFO" "$1" "$BLUE"
}

success() {
    _log_enabled "$LOG_LEVEL_INFO" || return 0
    _format_message "SUCCESS" "$1" "$CYAN"
}

debug() {
    _log_enabled "$LOG_LEVEL_DEBUG" || return 0
    _format_message "DEBUG" "$1" "$PURPLE"
}

trace() {
    _log_enabled "$LOG_LEVEL_TRACE" || return 0
    _format_message "TRACE" "$1" "$WHITE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

export -f error warning info debug success critical trace
export -f _resolve_log_level _log_enabled
export -f command_exists

WHIPTAIL_BACKTITLE="${WHIPTAIL_BACKTITLE:-PressHost}"
WHIPTAIL_DEFAULT_HEIGHT=20
WHIPTAIL_DEFAULT_WIDTH=70
TERM_HEIGHT=24
TERM_WIDTH=80
CALC_HEIGHT=20
CALC_WIDTH=70

_whiptail_has_tty() {
    [[ -r /dev/tty && -w /dev/tty ]]
}

_whiptail_msgbox() {
    local title="$1"
    local backtitle="$2"
    local message="$3"
    local height="$4"
    local width="$5"
    local newt_colors="${6:-}"

    local text
    text="$(printf '%b' "$message")"

    if command_exists whiptail && _whiptail_has_tty; then
        if [[ -n "$newt_colors" ]]; then
            if NEWT_COLORS="$newt_colors" whiptail --title "$title" --backtitle "$backtitle" --msgbox "$text" "$height" "$width" \
                </dev/tty >/dev/tty; then
                return 0
            fi
        else
            if whiptail --title "$title" --backtitle "$backtitle" --msgbox "$text" "$height" "$width" \
                </dev/tty >/dev/tty; then
            return 0
        fi
        fi

        printf '%b\n' "${title}: ${text}" >&2
        return 0
    fi

    printf '%b\n' "${title}: ${text}" >&2
    return 0
}

_whiptail_textbox_file() {
    local title="$1"
    local backtitle="$2"
    local file="$3"
    local height="$4"
    local width="$5"

    local render_file="$file"
    local tmp_render_file=""
    local wrap_width=$((width > 8 ? width - 4 : width))

    strip_ansi() {
        sed -r 's/\x1B\[[0-9;?]*[ -/]*[@-~]//g' | sed -r 's/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]//g'
    }

    if command_exists whiptail && _whiptail_has_tty; then
        if [[ -r "$file" ]]; then
            if command_exists mktemp; then
                tmp_render_file=$(mktemp /tmp/presshost-log.XXXXXX 2>/dev/null || true)
            fi

            if [[ -n "$tmp_render_file" ]]; then
                if command_exists fold; then
                    strip_ansi < "$file" | fold -w "$wrap_width" > "$tmp_render_file" 2>/dev/null || true
                else
                    strip_ansi < "$file" > "$tmp_render_file" 2>/dev/null || true
                fi
                render_file="$tmp_render_file"
            fi
        fi

        if whiptail --title "$title" --backtitle "$backtitle" --scrolltext --textbox "$render_file" "$height" "$width" \
            </dev/tty >/dev/tty; then
            [[ -n "$tmp_render_file" ]] && rm -f "$tmp_render_file" 2>/dev/null || true
            return 0
        fi

        [[ -n "$tmp_render_file" ]] && rm -f "$tmp_render_file" 2>/dev/null || true

        printf '%s\n' "${title}: could not render textbox; showing raw content below" >&2
    fi

    if [[ -r "$file" ]]; then
        cat "$file" >&2
    else
        printf '%s\n' "${title}: file not readable: ${file}" >&2
    fi
    return 0
}

get_terminal_size() {
    local term_lines term_cols
    term_lines=$(tput lines 2>/dev/null || echo 24)
    term_cols=$(tput cols 2>/dev/null || echo 80)
    
    TERM_HEIGHT=$((term_lines > 24 ? term_lines : 24))
    TERM_WIDTH=$((term_cols > 80 ? term_cols : 80))
}

calc_dialog_size() {
    local requested_height="${1:-$WHIPTAIL_DEFAULT_HEIGHT}"
    local requested_width="${2:-$WHIPTAIL_DEFAULT_WIDTH}"
    
    get_terminal_size
    
    local max_height=$((TERM_HEIGHT - 4))
    local max_width=$((TERM_WIDTH - 4))
    
    CALC_HEIGHT=$((requested_height < max_height ? requested_height : max_height))
    CALC_WIDTH=$((requested_width < max_width ? requested_width : max_width))
    
    [[ $CALC_HEIGHT -lt 8 ]] && CALC_HEIGHT=8
    [[ $CALC_WIDTH -lt 50 ]] && CALC_WIDTH=50
}

show_whiptail_error() {
    local message="$1"
    local title="${2:-Error}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 10 60
    _whiptail_msgbox "$title" "$backtitle" "$message" "$CALC_HEIGHT" "$CALC_WIDTH" "$PRESSHOST_NEWT_ERROR"
}

show_whiptail_warning() {
    local message="$1"
    local title="${2:-Warning}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 10 60
    _whiptail_msgbox "$title" "$backtitle" "⚠ ${message}" "$CALC_HEIGHT" "$CALC_WIDTH" "$PRESSHOST_NEWT_WARNING"
}

show_whiptail_info() {
    local message="$1"
    local title="${2:-Information}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 12 60
    _whiptail_msgbox "$title" "$backtitle" "$message" "$CALC_HEIGHT" "$CALC_WIDTH" "$PRESSHOST_NEWT_INFO"
}

show_whiptail_success() {
    local message="$1"
    local title="${2:-Success}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 12 60
    _whiptail_msgbox "$title" "$backtitle" "✓ ${message}" "$CALC_HEIGHT" "$CALC_WIDTH" "$PRESSHOST_NEWT_SUCCESS"
}

show_whiptail_textbox() {
    local file="$1"
    local title="${2:-Details}"
    local backtitle="${3:-$WHIPTAIL_BACKTITLE}"

    calc_dialog_size 1000 1000
    _whiptail_textbox_file "$title" "$backtitle" "$file" "$CALC_HEIGHT" "$CALC_WIDTH"
}

update_whiptail_progress() {
    local percent="$1"
    local message="$2"
    local progress_pipe="${3:-${PRESSHOST_PROGRESS_PIPE:-}}"
    local progress_fd="${PRESSHOST_PROGRESS_FD:-}"
    local gauge_pid="${PRESSHOST_GAUGE_PID:-}"

    if [[ -n "$gauge_pid" ]] && [[ "$gauge_pid" =~ ^[0-9]+$ ]]; then
        if ! kill -0 "$gauge_pid" 2>/dev/null; then
            return 0
        fi
    fi

    if [[ -n "$progress_fd" ]] && [[ "$progress_fd" =~ ^[0-9]+$ ]]; then
        local text
        text="$(printf '%b' "$message")"
        {
            printf 'XXX\n'
            printf '%s\n' "$percent"
            printf '%s\n' "$text"
            printf 'XXX\n'
        } >&${progress_fd} 2>/dev/null || true
        return 0
    fi
    
    if [[ -n "$progress_pipe" ]] && [[ -p "$progress_pipe" ]]; then
        local text
        text="$(printf '%b' "$message")"
        {
            printf 'XXX\n'
            printf '%s\n' "$percent"
            printf '%s\n' "$text"
            printf 'XXX\n'
        } >"$progress_pipe" 2>/dev/null || true
    fi
}

validate_email() {
    local email="$1"
    local regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    [[ "$email" =~ $regex ]]
}

validate_url() {
    local url="$1"

    local structure_regex='^https?://([^/:?#]+)(:([0-9]{1,5}))?([/?#].*)?$'
    if [[ ! "$url" =~ $structure_regex ]]; then
        return 1
    fi

    local host="${BASH_REMATCH[1]}"
    local port="${BASH_REMATCH[3]:-}"

    if [[ -n "$port" ]]; then
        [[ "$port" =~ ^[0-9]+$ ]] || return 1
        (( 10#$port >= 1 && 10#$port <= 65535 )) || return 1
    fi

    if [[ "$host" == "localhost" ]]; then
        return 0
    fi

    if [[ "$host" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        local o1 o2 o3 o4
        IFS='.' read -r o1 o2 o3 o4 <<<"$host"
        local o
        for o in "$o1" "$o2" "$o3" "$o4"; do
            [[ "$o" =~ ^[0-9]+$ ]] || return 1
            (( 10#$o >= 0 && 10#$o <= 255 )) || return 1
        done
        return 0
    fi

    local domain_regex='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
    [[ "$host" =~ $domain_regex ]]
}

validate_username() {
    local username="$1"
    local regex="^[a-zA-Z0-9_]{3,20}$"
    [[ "$username" =~ $regex ]]
}

validate_version() {
    local version="$1"
    local regex="^[0-9]+\.[0-9]+(\.[0-9]+)?$"
    [[ "$version" =~ $regex ]]
}

validate_locale() {
    local locale="$1"
    local regex='^[a-z]{2,3}(_[A-Za-z0-9]{2,8}){0,2}$'
    [[ "$locale" =~ $regex ]]
}

# Returns all locales (code,english_name) - one per line
get_all_locales() {
    cat <<'EOF'
af,Afrikaans
ar,Arabic
ary,Moroccan Arabic
as,Assamese
az,Azerbaijani
azb,South Azerbaijani
bel,Belarusian
bg_BG,Bulgarian
bn_BD,Bengali (Bangladesh)
bn_IN,Bengali (India)
bo,Tibetan
bs_BA,Bosnian
ca,Catalan
ceb,Cebuano
ckb,Kurdish (Sorani)
cs_CZ,Czech
cy,Welsh
da_DK,Danish
de_AT,German (Austria)
de_CH,German (Switzerland)
de_CH_informal,German (Switzerland Informal)
de_DE,German
de_DE_formal,German (Formal)
dzo,Dzongkha
el,Greek
en_AU,English (Australia)
en_CA,English (Canada)
en_GB,English (UK)
en_NZ,English (New Zealand)
en_US,English (United States)
en_ZA,English (South Africa)
eo,Esperanto
es_AR,Spanish (Argentina)
es_CL,Spanish (Chile)
es_CO,Spanish (Colombia)
es_CR,Spanish (Costa Rica)
es_ES,Spanish (Spain)
es_GT,Spanish (Guatemala)
es_MX,Spanish (Mexico)
es_PE,Spanish (Peru)
es_UY,Spanish (Uruguay)
es_VE,Spanish (Venezuela)
et,Estonian
eu,Basque
fa_IR,Persian
fi,Finnish
fr_BE,French (Belgium)
fr_CA,French (Canada)
fr_FR,French (France)
fur,Friulian
gd,Scottish Gaelic
gl_ES,Galician
gu,Gujarati
haz,Hazaragi
he_IL,Hebrew
hi_IN,Hindi
hr,Croatian
hsb,Upper Sorbian
hu_HU,Hungarian
hy,Armenian
id_ID,Indonesian
is_IS,Icelandic
it_IT,Italian
ja,Japanese
jv_ID,Javanese
kab,Kabyle
ka_GE,Georgian
kk,Kazakh
km,Khmer
kn,Kannada
ko_KR,Korean
lo,Lao
lt_LT,Lithuanian
lv,Latvian
mk_MK,Macedonian
ml_IN,Malayalam
mn,Mongolian
mr,Marathi
ms_MY,Malay
my_MM,Myanmar (Burmese)
nb_NO,Norwegian (Bokmal)
ne_NP,Nepali
nl_BE,Dutch (Belgium)
nl_NL,Dutch
nl_NL_formal,Dutch (Formal)
nn_NO,Norwegian (Nynorsk)
oci,Occitan
pa_IN,Punjabi
pl_PL,Polish
ps,Pashto
pt_AO,Portuguese (Angola)
pt_BR,Portuguese (Brazil)
pt_PT,Portuguese (Portugal)
pt_PT_ao90,Portuguese (Portugal AO90)
rhg,Rohingya
ro_RO,Romanian
ru_RU,Russian
sah,Sakha
si_LK,Sinhala
skr,Saraiki
sk_SK,Slovak
sl_SI,Slovenian
snd,Sindhi
sq,Albanian
sr_RS,Serbian
sv_SE,Swedish
sw,Swahili
szl,Silesian
tah,Tahitian
ta_IN,Tamil
te,Telugu
th,Thai
tl,Tagalog
tr_TR,Turkish
tt_RU,Tatar
ug_CN,Uighur
uk,Ukrainian
ur,Urdu
uz_UZ,Uzbek
vi,Vietnamese
zh_CN,Chinese (China)
zh_HK,Chinese (Hong Kong)
zh_TW,Chinese (Taiwan)
EOF
}

export -f get_all_locales
export -f get_terminal_size calc_dialog_size show_whiptail_error show_whiptail_warning show_whiptail_info show_whiptail_success show_whiptail_textbox update_whiptail_progress
export -f validate_email validate_url validate_username validate_version validate_locale

PRESS_WP_DIR="${APP_PATH:-/site/press}"
PRESS_UPLOADS_DIR="${UPLOADS_PATH:-/site/uploads}"
PRESS_CACHE_DIR="${CACHE_PATH:-/site/cache}"
PRESS_LOGS_DIR="${LOGS_PATH:-/site/logs}"
PRESS_USER="${APP_USER:-www-data}"
PRESS_GROUP="${APP_GROUP:-www-data}"
readonly PRESS_WP_CLI="/usr/local/bin/wp"
readonly PRESS_DEFAULT_TITLE="PressHost"
readonly PRESS_DEFAULT_USER="presshost"
readonly PRESS_DEFAULT_SKIP_EMAIL="true"
readonly PRESS_DEFAULT_LOCALE="en_US"

generate_local_salts() {
    local target_file="$1"
    local keys=(AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT)
    {
        echo "<?php"
        local key value
        for key in "${keys[@]}"; do
            value=$(openssl rand -base64 64 | tr -d '\n\r' | head -c 64)
            value="${value//\'/}"
            printf "define('%s', '%s');\n" "$key" "$value"
        done
    } > "$target_file"
}
export -f generate_local_salts

generate_password() {
    local length="${1:-16}"
    local out
    out=$(head -c 4096 /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_=+-' | cut -c1-"$length")
    if [[ ${#out} -ne $length ]]; then
        error "generate_password: got ${#out} chars, expected ${length}"
        return 1
    fi
    printf '%s' "$out"
}

download_press_archive() {
    local download_url="$1"
    local archive_file="$2"
    local press_name="${3:-Press}"
    local checksum_url="${4:-}"

    info "Downloading ${press_name} from: $download_url"
    if ! curl -fsSL --retry 3 --retry-delay 3 --connect-timeout 10 --max-time 300 "$download_url" -o "$archive_file"; then
        error "Failed to download ${press_name}"
        return 1
    fi
    success "${press_name} downloaded ($(du -h "$archive_file" | cut -f1))"

    if [[ -n "$checksum_url" ]]; then
        verify_press_archive_checksum "$archive_file" "$checksum_url" "$press_name" || return 1
    else
        warning "No checksum URL available for ${press_name}; archive integrity NOT verified"
    fi
}

verify_press_archive_checksum() {
    local archive_file="$1"
    local checksum_url="$2"
    local press_name="${3:-Press}"
    local expected_file=""

    expected_file=$(mktemp) || return 1
    if ! curl -fsSL --retry 3 --retry-delay 3 --connect-timeout 10 --max-time 300 "$checksum_url" -o "$expected_file"; then
        rm -f "$expected_file"
        error "Failed to download checksum for ${press_name}; aborting for safety"
        return 1
    fi

    local expected actual
    expected=$(awk '{print $1}' "$expected_file" | tr -d '[:space:]')
    rm -f "$expected_file"
    actual=$(sha1sum "$archive_file" | awk '{print $1}')

    if [[ -z "$expected" || "$expected" != "$actual" ]]; then
        error "Checksum mismatch for ${press_name} (expected: ${expected:-none}, got: $actual)"
        return 1
    fi
    success "${press_name} checksum verified (sha1)"
}

extract_press_archive() {
    local archive_file="$1"
    local dest_dir="$2"
    local press_name="${3:-Press}"

    info "Extracting ${press_name} files..."
    if unzip -q "$archive_file" -d "$dest_dir"; then
        success "${press_name} extracted successfully"
        return 0
    fi
    error "Failed to extract ${press_name}"
    return 1
}

install_press_files() {
    local source_dir="$1"
    local press_name="${2:-Press}"

    info "Installing ${press_name} files..."
    mkdir -p "$PRESS_WP_DIR"

    info "Copying ${press_name} files..."
    if ! cp -rf "${source_dir}"/. "$PRESS_WP_DIR/"; then
        error "Failed to copy ${press_name} files"
        return 1
    fi
    success "${press_name} files copied successfully"
    rm -f "${PRESS_WP_DIR}/wp-config-sample.php"

    set_press_permissions
}

set_press_permissions() {
    info "Setting file permissions..."
    chown -R "${PRESS_USER}:${PRESS_GROUP}" "$PRESS_WP_DIR"
    find "$PRESS_WP_DIR" -type d -exec chmod 755 {} +
    find "$PRESS_WP_DIR" -type f -exec chmod 644 {} +
    success "File permissions configured"
}

setup_press_content() {
    info "Setting up wp-content structure..."
    local dir
    for dir in uploads plugins themes upgrade cache; do
        local full_path="${PRESS_WP_DIR}/wp-content/${dir}"
        mkdir -p "$full_path"
        chown "${PRESS_USER}:${PRESS_GROUP}" "$full_path"
    done
    success "wp-content structure configured"
}

cleanup_temp_dir() {
    local temp_dir="$1"
    info "Cleaning up temporary files..."
    rm -rf "$temp_dir"
}

PRESS_TYPE=""
PRESS_VERSION=""

verify_press_installation() {
    PRESS_TYPE=""
    PRESS_VERSION=""
    
    local required_files=("wp-load.php" "wp-settings.php" "wp-blog-header.php" "index.php")
    for file in "${required_files[@]}"; do
        if [[ ! -f "${PRESS_WP_DIR}/${file}" ]]; then
            return 1
        fi
    done
    
    local version_file="${PRESS_WP_DIR}/wp-includes/version.php"
    
    if [[ -f "$version_file" ]]; then
        if grep -q '\$cp_version\s*=' "$version_file" 2>/dev/null || \
           grep -q "classicpress_version" "$version_file" 2>/dev/null || \
           [[ -f "${PRESS_WP_DIR}/wp-includes/classicpress/class-classicpress.php" ]]; then
            PRESS_TYPE="ClassicPress"
            PRESS_VERSION=$(grep -oP "\\\$cp_version\s*=\s*['\"]?\K[0-9]+\.[0-9]+(\.[0-9]+)?" "$version_file" 2>/dev/null || echo "")
            if [[ -z "$PRESS_VERSION" ]]; then
                PRESS_VERSION=$(grep -oP "\\\$wp_version\s*=\s*['\"]?\K[0-9]+\.[0-9]+(\.[0-9]+)?" "$version_file" 2>/dev/null || echo "")
            fi
        else
            PRESS_TYPE="WordPress"
            PRESS_VERSION=$(grep -oP "\\\$wp_version\s*=\s*['\"]?\K[0-9]+\.[0-9]+(\.[0-9]+)?" "$version_file" 2>/dev/null || echo "")
        fi
    else
        if [[ -f "${PRESS_WP_DIR}/wp-includes/classicpress/class-classicpress.php" ]]; then
            PRESS_TYPE="ClassicPress"
        else
            PRESS_TYPE="WordPress"
        fi
    fi
    
    if [[ -z "$PRESS_VERSION" ]] && command_exists wp; then
        PRESS_VERSION=$(wp core version --allow-root --path="$PRESS_WP_DIR" 2>/dev/null || echo "")
    fi

    [[ -z "$PRESS_VERSION" ]] && PRESS_VERSION="unknown"
    return 0
}

check_press_installed() {
    "$PRESS_WP_CLI" core is-installed --allow-root --path="$PRESS_WP_DIR" 2>/dev/null
}

create_press_config() {
    local press_name="${1:-Press}"
    local source_config="/tmp/wp-config.php"
    local target="${PRESS_WP_DIR}/wp-config.php"

    info "Setting up wp-config.php for ${press_name}..."

    if [[ -f "$target" ]]; then
        info "wp-config.php already exists, skipping creation"
        return 0
    fi

    cp "$source_config" "$target"
    chown "${PRESS_USER}:${PRESS_GROUP}" "$target"
    chmod 640 "$target"
    success "wp-config.php copied successfully"
}

generate_press_secrets() {
    local press_name="${1:-Press}"
    local secrets_file="${PRESS_WP_DIR}/wp-secrets.php"

    if [[ -n "${AUTH_KEY:-}${SECURE_AUTH_KEY:-}${LOGGED_IN_KEY:-}${NONCE_KEY:-}${AUTH_SALT:-}${SECURE_AUTH_SALT:-}${LOGGED_IN_SALT:-}${NONCE_SALT:-}" ]]; then
        info "Salt keys provided via environment variables"
        return 0
    fi

    info "Generating wp-secrets.php with locally-generated salt keys..."
    generate_local_salts "$secrets_file"
    chown "${PRESS_USER}:${PRESS_GROUP}" "$secrets_file"
    chmod 640 "$secrets_file"
    success "Salt keys generated successfully"
}

run_press_install() {
    local press_name="${1:-Press}"
    
    info "Running ${press_name} installation..."
    
    local site_url="${INSTALL_URL:-${WP_HOME:-${WP_SITEURL:-}}}"
    local site_title="${INSTALL_TITLE:-$PRESS_DEFAULT_TITLE}"
    local admin_user="${INSTALL_USER:-$PRESS_DEFAULT_USER}"
    local admin_pass="${INSTALL_PASS:-}"
    local admin_email="${INSTALL_EMAIL:-}"
    local skip_email="${INSTALL_SKIP_EMAIL:-$PRESS_DEFAULT_SKIP_EMAIL}"
    local locale="${INSTALL_LOCALE:-$PRESS_DEFAULT_LOCALE}"
    
    if [[ -z "$site_url" ]]; then
        warning "INSTALL_URL, WP_HOME, or WP_SITEURL must be set for automated installation"
        return 1
    fi
    
    if [[ -z "$admin_email" ]]; then
        warning "INSTALL_EMAIL must be set for automated installation"
        return 1
    fi
    
    local generated_pass=""
    if [[ -z "$admin_pass" ]]; then
        generated_pass=$(generate_password 16)
        admin_pass="$generated_pass"
    fi
    
    if check_press_installed; then
        warning "${press_name} is already installed in the database"
        return 0
    fi
    
    if ! create_press_config "$press_name"; then
        error "Failed to create wp-config.php"
        return 1
    fi
    
    generate_press_secrets "$press_name" || true
    
    info "Installing ${press_name}..."
    info "  URL: $site_url"
    info "  Title: $site_title"
    info "  Admin: $admin_user"

    local -a install_args=(
        "core" "install"
        "--allow-root"
        "--path=$PRESS_WP_DIR"
        "--url=$site_url"
        "--title=$site_title"
        "--admin_user=$admin_user"
        "--admin_password=$admin_pass"
        "--admin_email=$admin_email"
        "--locale=$locale"
    )
    [[ "$skip_email" == "true" ]] && install_args+=("--skip-email")

    if "$PRESS_WP_CLI" "${install_args[@]}"; then
        success "${press_name} installed successfully!"
        if [[ -n "$generated_pass" ]]; then
            local pass_file="${LOGS_PATH:-/site/logs}/initial-admin-password"
            local umask_old
            umask_old=$(umask)
            umask 077
            if printf '%s\n' "$generated_pass" > "$pass_file" 2>/dev/null; then
                umask "$umask_old"
                chmod 600 "$pass_file" 2>/dev/null || true
                echo ""
                echo "  Admin Username: $admin_user"
                echo "  Admin Password written to: $pass_file"
                echo "  Read it, then delete that file."
                echo ""
            else
                umask "$umask_old"
                warning "Could not write ${pass_file}; reset the admin password with 'wp user update'"
            fi
        fi
        return 0
    else
        error "${press_name} installation failed"
        return 1
    fi
}

export -f generate_password download_press_archive verify_press_archive_checksum extract_press_archive install_press_files
export -f set_press_permissions setup_press_content cleanup_temp_dir verify_press_installation
export -f check_press_installed create_press_config generate_press_secrets run_press_install

debug "Common utilities loaded successfully"
