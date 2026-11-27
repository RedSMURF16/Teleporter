/*
*
*	Teleporter by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*	Commands:
*       say /teleporter                    "Opens the Teleporter menu."
*       say_team /teleporter               "Opens the Teleporter menu."
*       teleporter_reload                  "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*       v1.1: Smaller models
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                         32
#define TELEPORTER_CHECK                10.0
#define TELEPORTER_OFFSET_BASE          120.0
#define TELEPORTER_OFFSET_MIN           65.0
#define TELEPORTER_OFFSET_MAX           900.0
#define TELEPORTER_OFFSET_STEP          10.0
#define TELEPORTER_GHOST_ALPHA          120
#define TELEPORTER_ROTATION_STEP        22.5
#define ADMIN_ACCESS                    ADMIN_RCON
#define TELEPORTER_KEY                  891277
#define TELEPORTER_ARRAY_ITEM           pev_iuser1
#define TELEPORTER_OWNER                pev_iuser1
#define RANDOM_MAX                      2500
#define TELEPORTER_DEATH_PENALTY        10000.0
#define PDATA_NEXT_ATTACK               83
#define XO_CBASEPLAYER                  5
#define XO_CBASEPLAYERWEAPON            4
#define EXIT_FRAME_COUNT                19
#define EXIT_FRAME_EPSILON              3
#define EXIT_BEAM_DIRECTION_DOWN_MIN    -0.75
#define SOUND_NAV                       "buttons/blip1.wav"
#define SOUND_REMOVE                    "buttons/button10.wav"
#define SOUND_ALERT                     "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.5
new const ERROR_FILE[]              = "Teleporter_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_TELEPORTER
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_DLIGHT             = (1 << 0),
    FLAG_SOUND              = (1 << 1),
    FLAG_COOLDOWN           = (1 << 2),
    FLAG_RANDOM             = (1 << 3),
    FLAG_PLAYERS_ONLY       = (1 << 4),

    FLAG_SHOW               = (1 << 5),
    FLAG_GHOST              = (1 << 6),
    FLAG_GROUND             = (1 << 7),
    FLAG_ACTIVE             = (1 << 8),
    FLAG_PLAYING            = (1 << 9),
    FLAG_LOCK               = (1 << 10),
    FLAG_PENDING            = (1 << 11)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum
{
    ENTITY_ENTER,
    ENTITY_EXIT
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_DEFAULT_EXIT[MAX_RESOURCE_PATH_LENGTH],
    SETTING_DEFAULT_GLOW[MAX_RESOURCE_PATH_LENGTH],
    Float:SETTING_DEFAULT_GLOW_SCALE,
    SETTING_DEFAULT_GLOW_COLOR[3],
    SETTING_DEFAULT_GLOW_ALPHA,
    SETTING_DEFAULT_BEAM,
    SETTING_DEFAULT_BEAM_WIDTH,
    SETTING_DEFAULT_BEAM_NOISE,
    SETTING_DEFAULT_BEAM_COLOR[3],
    SETTING_DEFAULT_BEAM_ALPHA,
    SETTING_DEFAULT_BEAM_LIFE,
    SETTING_DEFAULT_BEAM_SPEED,
    Float:SETTING_DEFAULT_EXIT_FRAMERATE,
    Float:SETTING_DEFAULT_EXIT_SCALE,
    SETTING_DEFAULT_EXIT_COLOR[3],
    SETTING_DEFAULT_EXIT_ALPHA,
    SETTING_DEFAULT_DLIGHT_RADIUS,
    SETTING_DEFAULT_DLIGHT_COLOR[3],
    SETTING_DEFAULT_DLIGHT_LIFE,
    SETTING_EXIT_BEAM_COUNT[2],
    Float:SETTING_EXIT_BEAM_LENGTH[2],
    SETTING_EXIT_BEAM_WIDTH[2],
    SETTING_EXIT_BEAM_NOISE[2],
    SETTING_EXIT_BEAM_COLOR[3],
    SETTING_EXIT_BEAM_ALPHA,
    SETTING_EXIT_BEAM_LIFE[2],
    SETTING_EXIT_BEAM_DLIGHT_RADIUS,
    SETTING_EXIT_BEAM_DLIGHT_LIFE[2],
    SETTING_EXIT_BEAM_DLIGHT_DECAY[2],

    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Array:SETTING_DEFAULT_SOUND_AMBIENT,
    Array:SETTING_DEFAULT_SOUND_TELEPORT,
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_RANDOM_X[2],
    Float:SETTING_RANDOM_Y[2],
    Float:SETTING_RANDOM_Z[2],
    bool:SETTING_STOP_VELOCITY_ON_TELEPORT,
    bool:SETTING_KILL_ON_EXIT,
    bool:SETTING_KILL_ON_EXIT_WORLD,

    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],
    Float:SETTING_ENTER_WIDTH,

    bool:SETTING_TELEPORTER_LOAD,
    Float:SETTING_TELEPORTER_TASK
}

enum _:TELEPORTER
{
    TELEPORTER_ID,
    TELEPORTER_ITEM,
    TELEPORTER_FLAGS,
    TELEPORTER_TEAM,
    TELEPORTER_ENTER,
    TELEPORTER_GLOW[2],
    TELEPORTER_EXIT,
    TELEPORTER_NAME[MAX_VALUE_LENGTH],
    TELEPORTER_SPRITE_EXIT[MAX_RESOURCE_PATH_LENGTH],
    TELEPORTER_SPRITE_GLOW[MAX_RESOURCE_PATH_LENGTH],

    Float:TELEPORTER_ORIGIN[3],
    Float:TELEPORTER_ORIGIN_EXIT[3],
    Float:TELEPORTER_ORIGIN_BEAM_START[3],
    Float:TELEPORTER_ORIGIN_BEAM_END[3],
    Float:TELEPORTER_ANGLES[3],
    Float:TELEPORTER_MINS[3],
    Float:TELEPORTER_MAXS[3],

    TELEPORTER_SOUND_AMBIENT_CURRENT[MAX_RESOURCE_PATH_LENGTH],
    Float:TELEPORTER_GLOW_SCALE,
    TELEPORTER_GLOW_COLOR[3],
    TELEPORTER_GLOW_ALPHA,
    TELEPORTER_BEAM,
    TELEPORTER_BEAM_WIDTH,
    TELEPORTER_BEAM_NOISE,
    TELEPORTER_BEAM_COLOR[3],
    TELEPORTER_BEAM_ALPHA,
    TELEPORTER_BEAM_LIFE,
    Float:TELEPORTER_EXIT_FRAMERATE,
    Float:TELEPORTER_EXIT_SCALE,
    TELEPORTER_EXIT_COLOR[3],
    TELEPORTER_EXIT_ALPHA,
    TELEPORTER_DLIGHT_RADIUS,
    TELEPORTER_DLIGHT_COLOR[3],
    TELEPORTER_DLIGHT_LIFE,
    TELEPORTER_EXIT_BEAM_COUNT[2],
    Float:TELEPORTER_EXIT_BEAM_LENGTH[2],
    TELEPORTER_EXIT_BEAM_WIDTH[2],
    TELEPORTER_EXIT_BEAM_NOISE[2],
    TELEPORTER_EXIT_BEAM_COLOR[3],
    TELEPORTER_EXIT_BEAM_ALPHA,
    TELEPORTER_EXIT_BEAM_LIFE[2],
    TELEPORTER_EXIT_DLIGHT_RADIUS[2],
    TELEPORTER_EXIT_DLIGHT_COLOR[3],
    TELEPORTER_EXIT_DLIGHT_LIFE[2],
    TELEPORTER_EXIT_DLIGHT_DECAY[2],
    Float:TELEPORTER_COOLDOWN[2],

    Float:TELEPORTER_NEXT_COOLDOWN
}

enum _:PLAYER_DATA
{
    PDATA_TELEPORTER_GHOST,
    PDATA_TELEPORTER_MENU,
    bool:PDATA_TELEPORTER_ACTION,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE,
    MENU_TELEPORT_EXIT
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_PLACE
}

enum
{
    EXIT_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate",
    "menuHandlerExit"
}

new g_szCN[] = "teleporter"

new Array:g_aTeleporter,
    Array:g_aTeleporterConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    HamHook:g_iFwdTouch, HamHook:g_iFwdPreThink, HamHook:g_iFwdKilled,
    g_iTeleporter, g_iTeleporterConfig

public plugin_init()
{
    register_plugin("Teleporter", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_Teleporter", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /teleporter",       "cmdMenu", ADMIN_ACCESS, "-- Opens the Teleporter menu.")
    register_clcmd("say_team /teleporter",  "cmdMenu", ADMIN_ACCESS, "-- Opens the Teleporter menu.")
    register_concmd("teleporter_reload",  "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("Teleporter.txt")

    g_iFwdTouch = RegisterHam(Ham_Touch, "info_target", "fwdTouch")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdKilled = RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableTeleporter()

    teleporterInit()
}

public plugin_precache()
{
    g_aTeleporter = ArrayCreate(TELEPORTER)
    g_aTeleporterConfig = ArrayCreate(TELEPORTER)
    g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aTeleporter)
    ArrayDestroy(g_aTeleporterConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    teleporterSound(id, SOUND_MENU_NAV)
    teleporterMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    teleporterReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aTeleporterConfig)
        ArrayClear(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT])
        ArrayClear(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT])
        g_iTeleporterConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/Teleporter.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eTeleporter[TELEPORTER], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iTeleporterConfig )
                            ArrayPushArray(g_aTeleporterConfig, eTeleporter)

                        copy(eTeleporter[TELEPORTER_NAME], charsmax(eTeleporter[TELEPORTER_NAME]), szData)
                        copy(eTeleporter[TELEPORTER_SPRITE_EXIT], charsmax(eTeleporter[TELEPORTER_SPRITE_EXIT]), g_eSettings[SETTING_DEFAULT_EXIT])
                        copy(eTeleporter[TELEPORTER_SPRITE_GLOW], charsmax(eTeleporter[TELEPORTER_SPRITE_GLOW]), g_eSettings[SETTING_DEFAULT_GLOW])
                        eTeleporter[TELEPORTER_FLAGS]                   = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eTeleporter[TELEPORTER_TEAM]                    = g_eSettings[SETTING_DEFAULT_TEAM]
                        eTeleporter[TELEPORTER_GLOW_SCALE]              = g_eSettings[SETTING_DEFAULT_GLOW_SCALE]
                        eTeleporter[TELEPORTER_GLOW_COLOR][0]           = g_eSettings[SETTING_DEFAULT_GLOW_COLOR][0]
                        eTeleporter[TELEPORTER_GLOW_COLOR][1]           = g_eSettings[SETTING_DEFAULT_GLOW_COLOR][1]
                        eTeleporter[TELEPORTER_GLOW_COLOR][2]           = g_eSettings[SETTING_DEFAULT_GLOW_COLOR][2]
                        eTeleporter[TELEPORTER_GLOW_ALPHA]              = g_eSettings[SETTING_DEFAULT_GLOW_ALPHA]
                        eTeleporter[TELEPORTER_BEAM]                    = g_eSettings[SETTING_DEFAULT_BEAM]
                        eTeleporter[TELEPORTER_BEAM_WIDTH]              = g_eSettings[SETTING_DEFAULT_BEAM_WIDTH]
                        eTeleporter[TELEPORTER_BEAM_NOISE]              = g_eSettings[SETTING_DEFAULT_BEAM_NOISE]
                        eTeleporter[TELEPORTER_BEAM_COLOR][0]           = g_eSettings[SETTING_DEFAULT_BEAM_COLOR][0]
                        eTeleporter[TELEPORTER_BEAM_COLOR][1]           = g_eSettings[SETTING_DEFAULT_BEAM_COLOR][1]
                        eTeleporter[TELEPORTER_BEAM_COLOR][2]           = g_eSettings[SETTING_DEFAULT_BEAM_COLOR][2]
                        eTeleporter[TELEPORTER_BEAM_ALPHA]              = g_eSettings[SETTING_DEFAULT_BEAM_ALPHA]
                        eTeleporter[TELEPORTER_EXIT_FRAMERATE]          = g_eSettings[SETTING_DEFAULT_EXIT_FRAMERATE]
                        eTeleporter[TELEPORTER_EXIT_SCALE]              = g_eSettings[SETTING_DEFAULT_EXIT_SCALE]
                        eTeleporter[TELEPORTER_EXIT_COLOR][0]           = g_eSettings[SETTING_DEFAULT_EXIT_COLOR][0]
                        eTeleporter[TELEPORTER_EXIT_COLOR][1]           = g_eSettings[SETTING_DEFAULT_EXIT_COLOR][1]
                        eTeleporter[TELEPORTER_EXIT_COLOR][2]           = g_eSettings[SETTING_DEFAULT_EXIT_COLOR][2]
                        eTeleporter[TELEPORTER_EXIT_ALPHA]              = g_eSettings[SETTING_DEFAULT_EXIT_ALPHA]
                        eTeleporter[TELEPORTER_DLIGHT_RADIUS]           = g_eSettings[SETTING_DEFAULT_DLIGHT_RADIUS]
                        eTeleporter[TELEPORTER_DLIGHT_COLOR][0]         = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][0]
                        eTeleporter[TELEPORTER_DLIGHT_COLOR][1]         = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][1]
                        eTeleporter[TELEPORTER_DLIGHT_COLOR][2]         = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][2]
                        eTeleporter[TELEPORTER_EXIT_BEAM_COUNT][0]      = g_eSettings[SETTING_EXIT_BEAM_COUNT][0]
                        eTeleporter[TELEPORTER_EXIT_BEAM_COUNT][1]      = g_eSettings[SETTING_EXIT_BEAM_COUNT][1]
                        eTeleporter[TELEPORTER_EXIT_BEAM_LENGTH][0]     = g_eSettings[SETTING_EXIT_BEAM_LENGTH][0]
                        eTeleporter[TELEPORTER_EXIT_BEAM_LENGTH][1]     = g_eSettings[SETTING_EXIT_BEAM_LENGTH][1]
                        eTeleporter[TELEPORTER_EXIT_BEAM_WIDTH][0]      = g_eSettings[SETTING_EXIT_BEAM_WIDTH][0]
                        eTeleporter[TELEPORTER_EXIT_BEAM_WIDTH][1]      = g_eSettings[SETTING_EXIT_BEAM_WIDTH][1]
                        eTeleporter[TELEPORTER_EXIT_BEAM_NOISE][0]      = g_eSettings[SETTING_EXIT_BEAM_NOISE][0]
                        eTeleporter[TELEPORTER_EXIT_BEAM_NOISE][1]      = g_eSettings[SETTING_EXIT_BEAM_NOISE][1]
                        eTeleporter[TELEPORTER_EXIT_BEAM_COLOR][0]      = g_eSettings[SETTING_EXIT_BEAM_COLOR][0]
                        eTeleporter[TELEPORTER_EXIT_BEAM_COLOR][1]      = g_eSettings[SETTING_EXIT_BEAM_COLOR][1]
                        eTeleporter[TELEPORTER_EXIT_BEAM_COLOR][2]      = g_eSettings[SETTING_EXIT_BEAM_COLOR][2]
                        eTeleporter[TELEPORTER_EXIT_BEAM_ALPHA]         = g_eSettings[SETTING_EXIT_BEAM_ALPHA]
                        eTeleporter[TELEPORTER_EXIT_BEAM_LIFE][0]       = g_eSettings[SETTING_EXIT_BEAM_LIFE][0]
                        eTeleporter[TELEPORTER_EXIT_BEAM_LIFE][1]       = g_eSettings[SETTING_EXIT_BEAM_LIFE][1]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_RADIUS]      = g_eSettings[SETTING_EXIT_BEAM_DLIGHT_RADIUS]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR][0]    = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][0]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR][1]    = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][1]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR][2]    = g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR][2]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_LIFE][0]     = g_eSettings[SETTING_EXIT_BEAM_DLIGHT_LIFE][0]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_LIFE][1]     = g_eSettings[SETTING_EXIT_BEAM_DLIGHT_LIFE][1]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_DECAY][0]    = g_eSettings[SETTING_EXIT_BEAM_DLIGHT_DECAY][0]
                        eTeleporter[TELEPORTER_EXIT_DLIGHT_DECAY][1]    = g_eSettings[SETTING_EXIT_BEAM_DLIGHT_DECAY][1]
                        eTeleporter[TELEPORTER_COOLDOWN][0]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eTeleporter[TELEPORTER_COOLDOWN][1]             = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]

                        iSection = SECTION_TELEPORTER
                        g_iTeleporterConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXIT") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXIT], charsmax(g_eSettings[SETTING_DEFAULT_EXIT]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW], charsmax(g_eSettings[SETTING_DEFAULT_GLOW]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW_SCALE], charsmax(g_eSettings[SETTING_DEFAULT_GLOW_SCALE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW_COLOR], charsmax(g_eSettings[SETTING_DEFAULT_GLOW_COLOR]))
                        else if ( equali(szKey, "SETTING_DEFAULT_GLOW_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_GLOW_ALPHA], charsmax(g_eSettings[SETTING_DEFAULT_GLOW_ALPHA]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BEAM") )
                            parseSetting(DTYPE_STRING_MODEL_ID, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BEAM], charsmax(g_eSettings[SETTING_DEFAULT_BEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BEAM_WIDTH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BEAM_WIDTH], charsmax(g_eSettings[SETTING_DEFAULT_BEAM_WIDTH]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BEAM_NOISE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BEAM_NOISE], charsmax(g_eSettings[SETTING_DEFAULT_BEAM_NOISE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BEAM_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BEAM_COLOR], charsmax(g_eSettings[SETTING_DEFAULT_BEAM_COLOR]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BEAM_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BEAM_ALPHA], charsmax(g_eSettings[SETTING_DEFAULT_BEAM_ALPHA]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BEAM_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BEAM_LIFE], charsmax(g_eSettings[SETTING_DEFAULT_BEAM_LIFE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_BEAM_SPEED") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_BEAM_SPEED], charsmax(g_eSettings[SETTING_DEFAULT_BEAM_SPEED]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXIT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXIT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_EXIT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXIT_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXIT_SCALE], charsmax(g_eSettings[SETTING_DEFAULT_EXIT_SCALE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXIT_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXIT_COLOR], charsmax(g_eSettings[SETTING_DEFAULT_EXIT_COLOR]))
                        else if ( equali(szKey, "SETTING_DEFAULT_EXIT_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_EXIT_ALPHA], charsmax(g_eSettings[SETTING_DEFAULT_EXIT_ALPHA]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DLIGHT_RADIUS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DLIGHT_RADIUS], charsmax(g_eSettings[SETTING_DEFAULT_DLIGHT_RADIUS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DLIGHT_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR], charsmax(g_eSettings[SETTING_DEFAULT_DLIGHT_COLOR]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DLIGHT_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DLIGHT_LIFE], charsmax(g_eSettings[SETTING_DEFAULT_DLIGHT_LIFE]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_COUNT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_COUNT], charsmax(g_eSettings[SETTING_EXIT_BEAM_COUNT]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_LENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_LENGTH], charsmax(g_eSettings[SETTING_EXIT_BEAM_LENGTH]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_WIDTH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_WIDTH], charsmax(g_eSettings[SETTING_EXIT_BEAM_WIDTH]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_NOISE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_NOISE], charsmax(g_eSettings[SETTING_EXIT_BEAM_NOISE]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_COLOR], charsmax(g_eSettings[SETTING_EXIT_BEAM_COLOR]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_ALPHA], charsmax(g_eSettings[SETTING_EXIT_BEAM_ALPHA]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_LIFE], charsmax(g_eSettings[SETTING_EXIT_BEAM_LIFE]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_DLIGHT_RADIUS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_DLIGHT_RADIUS], charsmax(g_eSettings[SETTING_EXIT_BEAM_DLIGHT_RADIUS]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_DLIGHT_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_DLIGHT_LIFE], charsmax(g_eSettings[SETTING_EXIT_BEAM_DLIGHT_LIFE]))
                        else if ( equali(szKey, "SETTING_EXIT_BEAM_DLIGHT_DECAY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_EXIT_BEAM_DLIGHT_DECAY], charsmax(g_eSettings[SETTING_EXIT_BEAM_DLIGHT_DECAY]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_AMBIENT") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_TELEPORT") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_RANDOM_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_RANDOM_X], charsmax(g_eSettings[SETTING_RANDOM_X]))
                        else if ( equali(szKey, "SETTING_RANDOM_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_RANDOM_Y], charsmax(g_eSettings[SETTING_RANDOM_Y]))
                        else if ( equali(szKey, "SETTING_RANDOM_Z") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_RANDOM_Z], charsmax(g_eSettings[SETTING_RANDOM_Z]))
                        else if ( equali(szKey, "SETTING_STOP_VELOCITY_ON_TELEPORT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT], charsmax(g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT]))
                        else if ( equali(szKey, "SETTING_KILL_ON_EXIT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_ON_EXIT], charsmax(g_eSettings[SETTING_KILL_ON_EXIT]))
                        else if ( equali(szKey, "SETTING_KILL_ON_EXIT_WORLD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_ON_EXIT_WORLD], charsmax(g_eSettings[SETTING_KILL_ON_EXIT_WORLD]))
                        else if ( equali(szKey, "SETTING_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS], charsmax(g_eSettings[SETTING_MINS]))
                        else if ( equali(szKey, "SETTING_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS], charsmax(g_eSettings[SETTING_MAXS]))
                        else if ( equali(szKey, "SETTING_ENTER_WIDTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_ENTER_WIDTH], charsmax(g_eSettings[SETTING_ENTER_WIDTH]))
                        else if ( equali(szKey, "SETTING_TELEPORTER_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_TELEPORTER_LOAD], charsmax(g_eSettings[SETTING_TELEPORTER_LOAD]))
                        else if ( equali(szKey, "SETTING_TELEPORTER_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_TELEPORTER_TASK], charsmax(g_eSettings[SETTING_TELEPORTER_TASK]))
                    }
                    case SECTION_TELEPORTER:
                    {
                        if ( equali(szKey, "TELEPORTER_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eTeleporter[TELEPORTER_FLAGS], charsmax(eTeleporter[TELEPORTER_FLAGS]))
                        else if ( equali(szKey, "TELEPORTER_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_TEAM], charsmax(eTeleporter[TELEPORTER_TEAM]))
                        else if ( equali(szKey, "TELEPORTER_SPRITE_EXIT") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), eTeleporter[TELEPORTER_SPRITE_EXIT], charsmax(eTeleporter[TELEPORTER_SPRITE_EXIT]))
                        else if ( equali(szKey, "TELEPORTER_SPRITE_GLOW") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), eTeleporter[TELEPORTER_SPRITE_GLOW], charsmax(eTeleporter[TELEPORTER_SPRITE_GLOW]))
                        else if ( equali(szKey, "TELEPORTER_GLOW_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_GLOW_SCALE], charsmax(eTeleporter[TELEPORTER_GLOW_SCALE]))
                        else if ( equali(szKey, "TELEPORTER_GLOW_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_GLOW_COLOR], charsmax(eTeleporter[TELEPORTER_GLOW_COLOR]))
                        else if ( equali(szKey, "TELEPORTER_GLOW_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_GLOW_ALPHA], charsmax(eTeleporter[TELEPORTER_GLOW_ALPHA]))
                        else if ( equali(szKey, "TELEPORTER_BEAM") )
                            parseSetting(DTYPE_STRING_MODEL_ID, szValue, charsmax(szValue), eTeleporter[TELEPORTER_BEAM], charsmax(eTeleporter[TELEPORTER_BEAM]))
                        else if ( equali(szKey, "TELEPORTER_BEAM_WIDTH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_BEAM_WIDTH], charsmax(eTeleporter[TELEPORTER_BEAM_WIDTH]))
                        else if ( equali(szKey, "TELEPORTER_BEAM_NOISE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_BEAM_NOISE], charsmax(eTeleporter[TELEPORTER_BEAM_NOISE]))
                        else if ( equali(szKey, "TELEPORTER_BEAM_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_BEAM_COLOR], charsmax(eTeleporter[TELEPORTER_BEAM_COLOR]))
                        else if ( equali(szKey, "TELEPORTER_BEAM_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_BEAM_ALPHA], charsmax(eTeleporter[TELEPORTER_BEAM_ALPHA]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_FRAMERATE], charsmax(eTeleporter[TELEPORTER_EXIT_FRAMERATE]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_SCALE], charsmax(eTeleporter[TELEPORTER_EXIT_SCALE]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_COLOR], charsmax(eTeleporter[TELEPORTER_EXIT_COLOR]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_ALPHA], charsmax(eTeleporter[TELEPORTER_EXIT_ALPHA]))
                        else if ( equali(szKey, "TELEPORTER_DLIGHT_RADIUS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_DLIGHT_RADIUS], charsmax(eTeleporter[TELEPORTER_DLIGHT_RADIUS]))
                        else if ( equali(szKey, "TELEPORTER_DLIGHT_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_DLIGHT_COLOR], charsmax(eTeleporter[TELEPORTER_DLIGHT_COLOR]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_BEAM_COUNT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_BEAM_COUNT], charsmax(eTeleporter[TELEPORTER_EXIT_BEAM_COUNT]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_BEAM_LENGTH") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_BEAM_LENGTH], charsmax(eTeleporter[TELEPORTER_EXIT_BEAM_LENGTH]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_BEAM_WIDTH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_BEAM_WIDTH], charsmax(eTeleporter[TELEPORTER_EXIT_BEAM_WIDTH]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_BEAM_NOISE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_BEAM_NOISE], charsmax(eTeleporter[TELEPORTER_EXIT_BEAM_NOISE]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_BEAM_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_BEAM_COLOR], charsmax(eTeleporter[TELEPORTER_EXIT_BEAM_COLOR]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_BEAM_ALPHA") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_BEAM_ALPHA], charsmax(eTeleporter[TELEPORTER_EXIT_BEAM_ALPHA]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_BEAM_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_BEAM_LIFE], charsmax(eTeleporter[TELEPORTER_EXIT_BEAM_LIFE]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_DLIGHT_RADIUS") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_DLIGHT_RADIUS], charsmax(eTeleporter[TELEPORTER_EXIT_DLIGHT_RADIUS]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_DLIGHT_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR], charsmax(eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_DLIGHT_LIFE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_DLIGHT_LIFE], charsmax(eTeleporter[TELEPORTER_EXIT_DLIGHT_LIFE]))
                        else if ( equali(szKey, "TELEPORTER_EXIT_DLIGHT_DECAY") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_EXIT_DLIGHT_DECAY], charsmax(eTeleporter[TELEPORTER_EXIT_DLIGHT_DECAY]))
                        else if ( equali(szKey, "TELEPORTER_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eTeleporter[TELEPORTER_COOLDOWN], charsmax(eTeleporter[TELEPORTER_COOLDOWN]))
                    }
                }
            }
        }
    }

    if ( g_iTeleporterConfig )
        ArrayPushArray(g_aTeleporterConfig, eTeleporter)
    else
        set_fail_state("No Teleporters were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eTeleporter[TELEPORTER], iItem
    if ( g_ePlayerData[id][PDATA_TELEPORTER_GHOST]
    && (iItem = teleporterGet(eTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_GHOST])) != -1 )
    {
        teleporterKill(eTeleporter)
        teleporterRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_TELEPORTER_GHOST]  = 0
    g_ePlayerData[id][PDATA_TELEPORTER_MENU]   = 0
}

stock teleporterInit()
{
    if ( g_eSettings[SETTING_TELEPORTER_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock teleporterTerminate()
{
    new eTeleporter[TELEPORTER]
    for ( new i = 0; i < g_iTeleporter; i ++ )
    {
        ArrayGetArray(g_aTeleporter, i, eTeleporter)
        eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_PLAYING
        if ( !(eTeleporter[TELEPORTER_FLAGS] & FLAG_PENDING) )
        {
            ArraySetArray(g_aTeleporter, i, eTeleporter)
            continue
        }

        eTeleporter[TELEPORTER_FLAGS] |= FLAG_ACTIVE
        eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_PENDING
        ArraySetArray(g_aTeleporter, i, eTeleporter)
    }
}

stock teleporterMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "TELEPORTER_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_ROOT_ROTATE"); }
        case MENU_TELEPORT_EXIT:    { menuExit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_ROOT_EXIT"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "TELEPORTER_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROOT_NOCLIP", id, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "TELEPORTER_ON" : "TELEPORTER_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROOT_GODMODE", id, (pev(id, pev_takedamage) == DAMAGE_NO) ? "TELEPORTER_ON" : "TELEPORTER_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iTeleporter >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_LIMIT", MAX_ENT)

                teleporterSound(id, SOUND_MENU_REMOVE)
                teleporterMenu(id, MENU_ROOT)
            }
            else
            {
                teleporterSound(id, SOUND_MENU_NAV)
                teleporterMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iTeleporter )
            {
                client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_NO_TELEPORTER")

                teleporterSound(id, SOUND_MENU_REMOVE)
                teleporterMenu(id, MENU_ROOT)
            }
            else
            {
                teleporterSound(id, SOUND_MENU_NAV)
                teleporterMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iTeleporter )
            {
                client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_NO_TELEPORTER")

                teleporterSound(id, SOUND_MENU_REMOVE)
                teleporterMenu(id, MENU_ROOT)
            }
            else
            {
                teleporterSound(id, SOUND_MENU_REMOVE)
                teleporterMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            teleporterNoClip(id)
        }
        case ROOT_GODMODE:
        {
            teleporterGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eTeleporter[TELEPORTER], szItem[64]
    for ( new i = 0; i < g_iTeleporterConfig; i ++ )
    {
        ArrayGetArray(g_aTeleporterConfig, i, eTeleporter)

        copy(szItem, charsmax(szItem), eTeleporter[TELEPORTER_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        teleporterSound(id, SOUND_MENU_NAV)
        teleporterMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    teleporterCreate(id, item)
    teleporterSound(id, SOUND_MENU_NAV)
    teleporterMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eTeleporter[TELEPORTER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_REMOVE_CURRENT", eTeleporter[TELEPORTER_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    teleporterSelect(eTeleporter, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)
}

public menuHandlerRemove(id, menu, item)
{
    new eTeleporter[TELEPORTER]
    ArrayGetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        teleporterSelect(eTeleporter, eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_TELEPORTER_MENU] >= g_iTeleporter - 1 )
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] ++

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_TELEPORTER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = g_iTeleporter - 1
            else
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] --

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_ACTIVE
            teleporterSetState(eTeleporter)
            teleporterKill(eTeleporter)
            teleporterRemove(g_ePlayerData[id][PDATA_TELEPORTER_MENU])

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_REMOVE_CURRENT", eTeleporter[TELEPORTER_NAME])
            g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0

            teleporterSound(id, g_iTeleporter > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            teleporterMenu(id, g_iTeleporter > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iTeleporter )
            {
                ArrayGetArray(g_aTeleporter, 0, eTeleporter)
                eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_ACTIVE

                teleporterSetState(eTeleporter)
                teleporterKill(eTeleporter)
                teleporterRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0

            teleporterSound(id, SOUND_MENU_ALERT)
            teleporterMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                teleporterSound(id, SOUND_MENU_NAV)
                teleporterMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eTeleporter[TELEPORTER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_SHOW_CURRENT",
    eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? "\y" : "\r", eTeleporter[TELEPORTER_NAME], id, eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? "TELEPORTER_SHOWN" : "TELEPORTER_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    teleporterSelect(eTeleporter, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)
}

public menuHandlerShow(id, menu, item)
{
    new eTeleporter[TELEPORTER]
    ArrayGetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        teleporterSelect(eTeleporter, eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_TELEPORTER_MENU] >= g_iTeleporter - 1 )
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] ++

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_TELEPORTER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = g_iTeleporter - 1
            else
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] --

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eTeleporter[TELEPORTER_FLAGS] ^= FLAG_SHOW
            if ( !(eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW) )
                eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_ACTIVE
            teleporterSetState(eTeleporter)

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_SHOW_CURRENT",
            eTeleporter[TELEPORTER_NAME], id, eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? "TELEPORTER_CHAT_SHOWN" : "TELEPORTER_CHAT_HIDDEN")
            ArraySetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iTeleporter; i ++ )
            {
                ArrayGetArray(g_aTeleporter, i, eTeleporter)
                eTeleporter[TELEPORTER_FLAGS] |= FLAG_SHOW
                teleporterSetState(eTeleporter)

                ArraySetArray(g_aTeleporter, i, eTeleporter)
            }

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_SHOW_ALL_SHOWN")
            teleporterSound(id, SOUND_MENU_ALERT)
            teleporterMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iTeleporter; i ++ )
            {
                ArrayGetArray(g_aTeleporter, i, eTeleporter)
                eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_SHOW
                eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_ACTIVE
                teleporterSetState(eTeleporter)

                ArraySetArray(g_aTeleporter, i, eTeleporter)
            }

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_SHOW_ALL_HIDDEN")
            teleporterSound(id, SOUND_MENU_ALERT)
            teleporterMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                teleporterSound(id, SOUND_MENU_NAV)
                teleporterMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eTeleporter[TELEPORTER]
    menuNav(id, iMenu)
    ArrayGetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_STATUS_CURRENT",
    eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eTeleporter[TELEPORTER_NAME], id, eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE ? "TELEPORTER_ENABLED" : "TELEPORTER_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    teleporterSelect(eTeleporter, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)
}

public menuHandlerStatus(id, menu, item)
{
    new eTeleporter[TELEPORTER]
    ArrayGetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        teleporterSelect(eTeleporter, eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_TELEPORTER_MENU] >= g_iTeleporter - 1 )
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
            else
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] ++

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_TELEPORTER_MENU] <= 0 )
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = g_iTeleporter - 1
            else
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] --

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eTeleporter[TELEPORTER_FLAGS] ^= FLAG_ACTIVE
            teleporterSetState(eTeleporter)

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_STATUS_CURRENT",
            eTeleporter[TELEPORTER_NAME], id, eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE ? "TELEPORTER_CHAT_ENABLED" : "TELEPORTER_CHAT_DISABLED")
            ArraySetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iTeleporter; i ++ )
            {
                ArrayGetArray(g_aTeleporter, i, eTeleporter)
                eTeleporter[TELEPORTER_FLAGS] |= FLAG_ACTIVE
                teleporterSetState(eTeleporter)

                ArraySetArray(g_aTeleporter, i, eTeleporter)
            }

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_STATUS_ALL_ENABLED")
            teleporterSound(id, SOUND_MENU_ALERT)
            teleporterMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iTeleporter; i ++ )
            {
                ArrayGetArray(g_aTeleporter, i, eTeleporter)
                eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_ACTIVE
                teleporterSetState(eTeleporter)

                ArraySetArray(g_aTeleporter, i, eTeleporter)
            }

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_STATUS_ALL_DISABLED")
            teleporterSound(id, SOUND_MENU_ALERT)
            teleporterMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                teleporterSound(id, SOUND_MENU_NAV)
                teleporterMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_TELEPORTER_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eTeleporter[TELEPORTER]
    if ( teleporterGet(eTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROTATE_GROUND",
    id, eTeleporter[TELEPORTER_FLAGS] & FLAG_GROUND ? "TELEPORTER_ON" : "TELEPORTER_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eTeleporter[TELEPORTER], iItem
    if ( (iItem = teleporterGet(eTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eTeleporter[TELEPORTER_ID], pev_angles, eTeleporter[TELEPORTER_ANGLES])
            eTeleporter[TELEPORTER_ANGLES][1] -= TELEPORTER_ROTATION_STEP
            if ( eTeleporter[TELEPORTER_ANGLES][1] < -180.0 ) eTeleporter[TELEPORTER_ANGLES][1] += 360.0

            set_pev(eTeleporter[TELEPORTER_ID], pev_angles, eTeleporter[TELEPORTER_ANGLES])
            ArraySetArray(g_aTeleporter, iItem, eTeleporter)

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eTeleporter[TELEPORTER_ID], pev_angles, eTeleporter[TELEPORTER_ANGLES])
            eTeleporter[TELEPORTER_ANGLES][1] += TELEPORTER_ROTATION_STEP
            if ( eTeleporter[TELEPORTER_ANGLES][1] > 180.0 ) eTeleporter[TELEPORTER_ANGLES][1] -= 360.0

            set_pev(eTeleporter[TELEPORTER_ID], pev_angles, eTeleporter[TELEPORTER_ANGLES])
            ArraySetArray(g_aTeleporter, iItem, eTeleporter)

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eTeleporter[TELEPORTER_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aTeleporter, iItem, eTeleporter)

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            teleporterTrace(eTeleporter, id)
            eTeleporter[TELEPORTER_FLAGS] |= FLAG_SHOW
            eTeleporter[TELEPORTER_ANGLES][0] = -eTeleporter[TELEPORTER_ANGLES][0]
            if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_RANDOM )
            {
                DisableAction(id)
                set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
                eTeleporter[TELEPORTER_FLAGS] |= FLAG_ACTIVE
                eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_GHOST
                g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = 0

                teleporterSetSize(eTeleporter)
                teleporterSetState(eTeleporter)
                client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_CREATE_NEW", eTeleporter[TELEPORTER_NAME])
            }
            else
            {
                teleporterCreateExit(eTeleporter)
                teleporterSetSize(eTeleporter)
            }

            ArraySetArray(g_aTeleporter, iItem, eTeleporter)
            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, eTeleporter[TELEPORTER_FLAGS] & FLAG_RANDOM ? MENU_CREATE : MENU_TELEPORT_EXIT)
        }
        case MENU_EXIT:
        {
            teleporterKill(eTeleporter)
            teleporterRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = 0

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_CREATE)
        }
        default:
        {
            teleporterKill(eTeleporter)
            teleporterRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuExit(id, iMenu)
{
    new szItem[64], eTeleporter[TELEPORTER]
    if ( teleporterGet(eTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "TELEPORTER_EXIT_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerExit(id, menu, item)
{
    new eTeleporter[TELEPORTER], iItem
    if ( (iItem = teleporterGet(eTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch ( item )
    {
        case EXIT_PLACE:
        {
            DisableAction(id)
            teleporterTrace(eTeleporter, id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = 0
            eTeleporter[TELEPORTER_FLAGS] |= FLAG_ACTIVE
            eTeleporter[TELEPORTER_FLAGS] &= ~(FLAG_GHOST | FLAG_LOCK)
            pev(eTeleporter[TELEPORTER_EXIT], pev_origin, eTeleporter[TELEPORTER_ORIGIN_EXIT])
            set_pev(eTeleporter[TELEPORTER_EXIT], pev_movetype, MOVETYPE_NONE)
            set_pev(eTeleporter[TELEPORTER_EXIT], pev_renderamt, 0.0)

            teleporterSetState(eTeleporter)
            ArraySetArray(g_aTeleporter, iItem, eTeleporter)

            client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_CREATE_NEW", eTeleporter[TELEPORTER_NAME])
            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            teleporterKill(eTeleporter)
            teleporterRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = 0

            teleporterSound(id, SOUND_MENU_NAV)
            teleporterMenu(id, MENU_CREATE)
        }
        default:
        {
            teleporterKill(eTeleporter)
            teleporterRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public teleporterTask()
{
    new eTeleporter[TELEPORTER], Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new i = 0; i < g_iTeleporter; i ++ )
    {
        ArrayGetArray(g_aTeleporter, i, eTeleporter)
        if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW )
        {
            if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE )
            {
                teleporterBeam(eTeleporter)
                if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_DLIGHT )
                    teleporterDLight(eTeleporter, ENTITY_ENTER)
            }
            else
            {
                if ( eTeleporter[TELEPORTER_NEXT_COOLDOWN] > 0.0
                && fCurrentTime >= eTeleporter[TELEPORTER_NEXT_COOLDOWN] )
                {
                    eTeleporter[TELEPORTER_FLAGS] |= FLAG_ACTIVE
                    eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_PENDING
                    teleporterSetState(eTeleporter)
                    ArraySetArray(g_aTeleporter, i, eTeleporter)
                }
            }
        }
    }
}

stock teleporterCreate(id, iItem)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new eTeleporter[TELEPORTER]
    ArrayGetArray(g_aTeleporterConfig, iItem, eTeleporter)
    eTeleporter[TELEPORTER_ID] = iEnt
    eTeleporter[TELEPORTER_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = eTeleporter[TELEPORTER_ID]
        g_ePlayerData[id][PDATA_OFFSET] = TELEPORTER_OFFSET_BASE

        eTeleporter[TELEPORTER_FLAGS] |= FLAG_GHOST
    }

    teleporterSelect(eTeleporter, TARGET_GHOST, false)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, TELEPORTER_KEY)
    set_pev(iEnt, TELEPORTER_ARRAY_ITEM, g_iTeleporter)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_DEFAULT_MODEL])

    ArrayPushArray(g_aTeleporter, eTeleporter)
    if ( ++ g_iTeleporter == 1 )
    {
        set_task(g_eSettings[SETTING_TELEPORTER_TASK], "teleporterTask", TELEPORTER_KEY, .flags = "b")
        EnableTeleporter()
    }
}

stock teleportCreateEnter(eTeleporter[TELEPORTER])
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new szCN[32]
    formatex(szCN, charsmax(szCN), "%s_enter", g_szCN)

    eTeleporter[TELEPORTER_ENTER] = iEnt
    set_pev(iEnt, TELEPORTER_OWNER, eTeleporter[TELEPORTER_ID])
    set_pev(iEnt, pev_classname, szCN)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_TRIGGER)
    set_pev(iEnt, pev_movetype, MOVETYPE_NONE)

    new Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3], Float:fHalfWidth, Float:fHalfHeight
    xs_vec_add(eTeleporter[TELEPORTER_ORIGIN_BEAM_START], eTeleporter[TELEPORTER_ORIGIN_BEAM_END], fOrigin)
    xs_vec_mul_scalar(fOrigin, 0.5, fOrigin)
    engfunc(EngFunc_SetOrigin, iEnt, fOrigin)

    fHalfWidth  = g_eSettings[SETTING_ENTER_WIDTH] * 0.5
    fHalfHeight = floatabs(eTeleporter[TELEPORTER_ORIGIN_BEAM_END][2] - eTeleporter[TELEPORTER_ORIGIN_BEAM_START][2]) * 0.5

    fMins[0] = -fHalfWidth
    fMins[1] = -fHalfWidth
    fMins[2] = -fHalfHeight
    fMaxs[0] = fHalfWidth
    fMaxs[1] = fHalfWidth
    fMaxs[2] = fHalfHeight
    engfunc(EngFunc_SetSize, iEnt, fMins, fMaxs)
}

stock teleporterCreateGlow(eTeleporter[TELEPORTER])
{
    new iEnt, szCN[32], Float:fOrigin[3]
    formatex(szCN, charsmax(szCN), "%s_glow", g_szCN)

    for ( new i = 0; i < 2; i ++ )
    {
        iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
        if ( !pev_valid(iEnt) )
            continue

        eTeleporter[TELEPORTER_GLOW][i] = iEnt
        set_pev(iEnt, TELEPORTER_OWNER, eTeleporter[TELEPORTER_ID])
        set_pev(iEnt, pev_classname, szCN)
        set_pev(iEnt, pev_spawnflags, SF_SPRITE_STARTON)
        engfunc(EngFunc_SetModel, iEnt, eTeleporter[TELEPORTER_SPRITE_GLOW])
        dllfunc(DLLFunc_Spawn, iEnt)
        set_pev(iEnt, pev_solid, SOLID_NOT)
        set_pev(iEnt, pev_movetype, MOVETYPE_NONE)

        if ( i == 0 )   xs_vec_copy(eTeleporter[TELEPORTER_ORIGIN_BEAM_START], fOrigin)
        else            xs_vec_copy(eTeleporter[TELEPORTER_ORIGIN_BEAM_END], fOrigin)
        engfunc(EngFunc_SetOrigin, iEnt, fOrigin)

        set_pev(iEnt, pev_scale, eTeleporter[TELEPORTER_GLOW_SCALE])
        entitySetRendering(iEnt, kRenderFxNone, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, 0)
    }
}

stock teleporterCreateExit(eTeleporter[TELEPORTER])
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
    if ( !pev_valid(iEnt) )
        return

    new szCN[32]
    eTeleporter[TELEPORTER_EXIT] = iEnt
    eTeleporter[TELEPORTER_FLAGS] |= FLAG_LOCK
    formatex(szCN, charsmax(szCN), "%s_exit", g_szCN)

    set_pev(iEnt, TELEPORTER_OWNER, eTeleporter[TELEPORTER_ID])
    set_pev(iEnt, pev_classname, szCN)
    set_pev(iEnt, pev_framerate, eTeleporter[TELEPORTER_EXIT_FRAMERATE])
    set_pev(iEnt, pev_spawnflags, SF_SPRITE_STARTON)
    engfunc(EngFunc_SetModel, iEnt, eTeleporter[TELEPORTER_SPRITE_EXIT])
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)

    set_pev(iEnt, pev_scale, eTeleporter[TELEPORTER_EXIT_SCALE])
    entitySetRendering(iEnt, kRenderFxNone, eTeleporter[TELEPORTER_EXIT_COLOR][0], eTeleporter[TELEPORTER_EXIT_COLOR][1], eTeleporter[TELEPORTER_EXIT_COLOR][2], kRenderTransAdd, eTeleporter[TELEPORTER_EXIT_ALPHA])
}

public teleporterRemove(iItem)
{
    new eTeleporter[TELEPORTER]
    ArrayDeleteItem(g_aTeleporter, iItem)
    if ( -- g_iTeleporter == 0 )
    {
        remove_task(TELEPORTER_KEY)
        DisableTeleporter()
    }

    for ( new i = iItem; i < g_iTeleporter; i ++ )
    {
        ArrayGetArray(g_aTeleporter, i, eTeleporter)
        set_pev(eTeleporter[TELEPORTER_ID], TELEPORTER_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eTeleporter[TELEPORTER],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Teleporter.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    teleporterTerminate()
    for ( new i = 0; i < g_iTeleporter; i ++ )
    {
        ArrayGetArray(g_aTeleporter, i, eTeleporter)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eTeleporter[TELEPORTER_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eTeleporter[TELEPORTER_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eTeleporter[TELEPORTER_ORIGIN][0], eTeleporter[TELEPORTER_ORIGIN][1], eTeleporter[TELEPORTER_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eTeleporter[TELEPORTER_ANGLES][0], eTeleporter[TELEPORTER_ANGLES][1], eTeleporter[TELEPORTER_ANGLES][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "exit = %.2f %.2f %.2f^n",
        eTeleporter[TELEPORTER_ORIGIN_EXIT][0], eTeleporter[TELEPORTER_ORIGIN_EXIT][1], eTeleporter[TELEPORTER_ORIGIN_EXIT][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "TELEPORTER_CHAT_TAG", id, "TELEPORTER_CHAT_SAVE", szFile)
    fclose(iFile)

    teleporterSound(id, SOUND_MENU_NAV)
    teleporterMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], Float:fExit[3],
        iItem, iFlags, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_Teleporter.ini", szFile)

    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataTeleporter(iItem, iFlags, fOrigin, fAngles, fExit, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "exit") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fExit[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fExit[1] = str_to_float(szKey)
                fExit[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataTeleporter(iItem, iFlags, fOrigin, fAngles, fExit, iCount)

    fclose(iFile)
}

stock LoadDataTeleporter(iItem, iFlags, Float:fOrigin[3], Float:fAngles[3], Float:fExit[3], iCount)
{
    new eTeleporter[TELEPORTER]
    teleporterCreate(0, iItem)
    ArrayGetArray(g_aTeleporter, iCount, eTeleporter)

    eTeleporter[TELEPORTER_FLAGS] = iFlags
    xs_vec_copy(fOrigin, eTeleporter[TELEPORTER_ORIGIN])
    xs_vec_copy(fAngles, eTeleporter[TELEPORTER_ANGLES])
    xs_vec_copy(fExit, eTeleporter[TELEPORTER_ORIGIN_EXIT])

    if ( !(eTeleporter[TELEPORTER_FLAGS] & FLAG_RANDOM) )
    {
        teleporterCreateExit(eTeleporter)
        set_pev(eTeleporter[TELEPORTER_EXIT], pev_origin, eTeleporter[TELEPORTER_ORIGIN_EXIT])
        set_pev(eTeleporter[TELEPORTER_EXIT], pev_movetype, MOVETYPE_NONE)
        set_pev(eTeleporter[TELEPORTER_EXIT], pev_renderamt, 0.0)
    }

    teleporterSetBox(eTeleporter)
    teleporterSetSize(eTeleporter)
    teleporterSetState(eTeleporter)
    ArraySetArray(g_aTeleporter, iCount, eTeleporter)
}

public teleporterNoClip(id)
{
    set_pev(id, pev_movetype, pev(id, pev_movetype) == MOVETYPE_NOCLIP ? MOVETYPE_WALK : MOVETYPE_NOCLIP)

    teleporterSound(id, SOUND_MENU_NAV)
    teleporterMenu(id, MENU_ROOT)
}

public teleporterGodMode(id)
{
    set_pev(id, pev_takedamage, pev(id, pev_takedamage) == DAMAGE_NO ? DAMAGE_AIM : DAMAGE_NO)

    teleporterSound(id, SOUND_MENU_NAV)
    teleporterMenu(id, MENU_ROOT)
}

public fwdTouch(iEnt, iOther)
{
    if ( !isTeleporter(pev(iEnt, TELEPORTER_OWNER))
    || pev(iOther, pev_solid) == SOLID_NOT
    || pev(iOther, pev_movetype) == MOVETYPE_NONE
    || pev(iOther, pev_movetype) == MOVETYPE_FOLLOW )
        return HAM_IGNORED

    new eTeleporter[TELEPORTER], iItem
    if ( (iItem = teleporterGet(eTeleporter, pev(iEnt, TELEPORTER_OWNER))) == -1
    || !(eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE)
    || (eTeleporter[TELEPORTER_FLAGS] & FLAG_PLAYERS_ONLY && !is_user_alive(iOther))
    || (is_user_alive(iOther) && !(eTeleporter[TELEPORTER_TEAM] & get_user_team(iOther))) )
        return HAM_IGNORED

    new szSound[MAX_RESOURCE_PATH_LENGTH], iTarget, iHit
    iTarget = g_eSettings[SETTING_KILL_ON_EXIT_WORLD] ? 0 : iOther
    ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_TELEPORT])), szSound, charsmax(szSound))
    if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_RANDOM )
    {
        new Float:fOrigin[3]
        for ( new i = 0; i < RANDOM_MAX; i ++ )
        {
            xs_vec_copy(eTeleporter[TELEPORTER_ORIGIN], fOrigin)
            fOrigin[0] += random_float(g_eSettings[SETTING_RANDOM_X][0], g_eSettings[SETTING_RANDOM_X][1])
            fOrigin[1] += random_float(g_eSettings[SETTING_RANDOM_Y][0], g_eSettings[SETTING_RANDOM_Y][1])
            fOrigin[2] += random_float(g_eSettings[SETTING_RANDOM_Z][0], g_eSettings[SETTING_RANDOM_Z][1])
            engfunc(EngFunc_TraceHull, fOrigin, fOrigin, DONT_IGNORE_MONSTERS, HULL_HUMAN, iOther, 0)
            if ( get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) )
                continue

            iHit = get_tr2(0, TR_pHit)
            if ( g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT] )
                set_pev(iOther, pev_velocity, NULL_VECTOR)

            if ( g_eSettings[SETTING_KILL_ON_EXIT]
            && pev_valid(iHit)
            && pev(iHit, pev_takedamage) != DAMAGE_NO )
                ExecuteHamB(Ham_TakeDamage, iHit, iTarget, iTarget, TELEPORTER_DEATH_PENALTY, DMG_ALWAYSGIB)

            if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_COOLDOWN )
            {
                eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_ACTIVE
                eTeleporter[TELEPORTER_FLAGS] |= FLAG_PENDING
                eTeleporter[TELEPORTER_NEXT_COOLDOWN] = get_gametime() + random_float(eTeleporter[TELEPORTER_COOLDOWN][0], eTeleporter[TELEPORTER_COOLDOWN][1])
                teleporterSetState(eTeleporter)
            }

            engfunc(EngFunc_SetOrigin, iOther, fOrigin)
            engfunc(EngFunc_EmitSound, iOther, CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
            teleportExit(eTeleporter)
            teleportExitBeam(eTeleporter)
            teleporterDLight(eTeleporter, ENTITY_EXIT)
            ArraySetArray(g_aTeleporter, iItem, eTeleporter)
            break
        }
    }
    else
    {
        if ( g_eSettings[SETTING_STOP_VELOCITY_ON_TELEPORT] )
            set_pev(iOther, pev_velocity, NULL_VECTOR)

        if ( g_eSettings[SETTING_KILL_ON_EXIT] )
        {
            engfunc(EngFunc_TraceHull, eTeleporter[TELEPORTER_ORIGIN_EXIT], eTeleporter[TELEPORTER_ORIGIN_EXIT], DONT_IGNORE_MONSTERS, HULL_HUMAN, 0, 0)
            iHit = get_tr2(0, TR_pHit)

            if ( pev_valid(iHit)
            && pev(iHit, pev_takedamage) != DAMAGE_NO )
                ExecuteHamB(Ham_TakeDamage, iHit, iTarget, iTarget, TELEPORTER_DEATH_PENALTY, DMG_ALWAYSGIB)
        }

        if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_COOLDOWN )
        {
            eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_ACTIVE
            eTeleporter[TELEPORTER_FLAGS] |= FLAG_PENDING
            eTeleporter[TELEPORTER_NEXT_COOLDOWN] = get_gametime() + random_float(eTeleporter[TELEPORTER_COOLDOWN][0], eTeleporter[TELEPORTER_COOLDOWN][1])
            teleporterSetState(eTeleporter)
        }

        engfunc(EngFunc_SetOrigin, iOther, eTeleporter[TELEPORTER_ORIGIN_EXIT])
        engfunc(EngFunc_EmitAmbientSound, iOther, CHAN_BODY, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
        teleportExit(eTeleporter)
        teleportExitBeam(eTeleporter)
        teleporterDLight(eTeleporter, ENTITY_EXIT)
        ArraySetArray(g_aTeleporter, iItem, eTeleporter)
    }

    return HAM_IGNORED
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eTeleporter[TELEPORTER], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( teleporterGet(eTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_TELEPORTER_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += TELEPORTER_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], TELEPORTER_OFFSET_MIN, TELEPORTER_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= TELEPORTER_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], TELEPORTER_OFFSET_MIN, TELEPORTER_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            teleporterTrace(eTeleporter, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_TELEPORTER_ACTION] )
    {
        teleporterCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_TELEPORTER_MENU]   = 0
    if ( g_ePlayerData[id][PDATA_TELEPORTER_GHOST] )
    {
        new eTeleporter[TELEPORTER], iItem
        if ( (iItem = teleporterGet(eTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_GHOST])) != -1 )
        {
            teleporterKill(eTeleporter)
            teleporterRemove(iItem)
        }

        g_ePlayerData[id][PDATA_TELEPORTER_GHOST] = 0
    }
}

stock teleporterTrace(eTeleporter[TELEPORTER], id)
{
    new Float:fVec1[3], Float:fVec2[3]

    pev(id, pev_origin, fVec1)
    if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_LOCK )
    {
        pev(id, pev_view_ofs, fVec2)
        xs_vec_add(fVec1, fVec2, fVec1)
    }
    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    xs_vec_mul_scalar(fVec2, g_ePlayerData[id][PDATA_OFFSET], fVec2)
    xs_vec_add(fVec2, fVec1, fVec2)
    engfunc(EngFunc_TraceLine, fVec1, fVec2, DONT_IGNORE_MONSTERS, id, 0)

    if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_LOCK )
    {
        get_tr2(0, TR_vecEndPos, fVec1)
        set_pev(eTeleporter[TELEPORTER_EXIT], pev_origin, fVec1)
    }
    else
    {
        get_tr2(0, TR_vecEndPos, eTeleporter[TELEPORTER_ORIGIN])
        teleporterSetBox(eTeleporter)
        teleporterSetOffset(eTeleporter)
        set_pev(eTeleporter[TELEPORTER_ID], pev_origin, eTeleporter[TELEPORTER_ORIGIN])
    }
}

stock teleporterCheck(id)
{
    new eTeleporter[TELEPORTER], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = TELEPORTER_CHECK
    for ( new i = 0; i < g_iTeleporter; i ++ )
    {
        ArrayGetArray(g_aTeleporter, i, eTeleporter)
        xs_vec_sub(eTeleporter[TELEPORTER_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eTeleporter[TELEPORTER_ID], pev_absmin, fMins)
        pev(eTeleporter[TELEPORTER_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = vector_distance(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_TELEPORTER_MENU] != iBest )
    {
        ArrayGetArray(g_aTeleporter, g_ePlayerData[id][PDATA_TELEPORTER_MENU], eTeleporter)
        teleporterSelect(eTeleporter, eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_TELEPORTER_MENU] = iBest
        teleporterMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock teleporterBeam(eTeleporter[TELEPORTER])
{
    message_begin_f(MSG_PVS, SVC_TEMPENTITY, eTeleporter[TELEPORTER_ORIGIN])
    write_byte(TE_BEAMPOINTS)
    write_coord_f(eTeleporter[TELEPORTER_ORIGIN_BEAM_START][0])
    write_coord_f(eTeleporter[TELEPORTER_ORIGIN_BEAM_START][1])
    write_coord_f(eTeleporter[TELEPORTER_ORIGIN_BEAM_START][2])
    write_coord_f(eTeleporter[TELEPORTER_ORIGIN_BEAM_END][0])
    write_coord_f(eTeleporter[TELEPORTER_ORIGIN_BEAM_END][1])
    write_coord_f(eTeleporter[TELEPORTER_ORIGIN_BEAM_END][2])
    write_short(eTeleporter[TELEPORTER_BEAM])
    write_byte(0)
    write_byte(0)
    write_byte(g_eSettings[SETTING_DEFAULT_BEAM_LIFE])
    write_byte(eTeleporter[TELEPORTER_BEAM_WIDTH])
    write_byte(eTeleporter[TELEPORTER_BEAM_NOISE])
    write_byte(eTeleporter[TELEPORTER_BEAM_COLOR][0])
    write_byte(eTeleporter[TELEPORTER_BEAM_COLOR][1])
    write_byte(eTeleporter[TELEPORTER_BEAM_COLOR][2])
    write_byte(eTeleporter[TELEPORTER_BEAM_ALPHA])
    write_byte(g_eSettings[SETTING_DEFAULT_BEAM_SPEED])
    message_end()
}

stock teleporterDLight(eTeleporter[TELEPORTER], iEntity)
{
    if ( iEntity == ENTITY_ENTER )
    {
        message_begin_f(MSG_PVS, SVC_TEMPENTITY, eTeleporter[TELEPORTER_ORIGIN])
        write_byte(TE_DLIGHT)
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN][0])
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN][1])
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN][2])
        write_byte(eTeleporter[TELEPORTER_DLIGHT_RADIUS])
        write_byte(eTeleporter[TELEPORTER_DLIGHT_COLOR][0])
        write_byte(eTeleporter[TELEPORTER_DLIGHT_COLOR][1])
        write_byte(eTeleporter[TELEPORTER_DLIGHT_COLOR][2])
        write_byte(g_eSettings[SETTING_DEFAULT_DLIGHT_LIFE])
        write_byte(0)
        message_end()
    }
    else
    {
        message_begin_f(MSG_PVS, SVC_TEMPENTITY, eTeleporter[TELEPORTER_ORIGIN_EXIT])
        write_byte(TE_DLIGHT)
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN_EXIT][0])
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN_EXIT][1])
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN_EXIT][2])
        write_byte(random_num(eTeleporter[TELEPORTER_EXIT_DLIGHT_RADIUS][0], eTeleporter[TELEPORTER_EXIT_DLIGHT_RADIUS][1]))
        write_byte(eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR][0])
        write_byte(eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR][1])
        write_byte(eTeleporter[TELEPORTER_EXIT_DLIGHT_COLOR][2])
        write_byte(random_num(eTeleporter[TELEPORTER_EXIT_DLIGHT_LIFE][0], eTeleporter[TELEPORTER_EXIT_DLIGHT_LIFE][1]))
        write_byte(random_num(eTeleporter[TELEPORTER_EXIT_DLIGHT_DECAY][0], eTeleporter[TELEPORTER_EXIT_DLIGHT_DECAY][1]))
        message_end()
    }
}

stock teleportExit(eTeleporter[TELEPORTER])
{
    new iEnt = eTeleporter[TELEPORTER_EXIT]
    if ( !pev_valid(iEnt) )
        return

    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_animtime, get_gametime())
    set_pev(iEnt, pev_renderamt, float(eTeleporter[TELEPORTER_EXIT_ALPHA]))

    remove_task(iEnt)
    set_task(float(EXIT_FRAME_COUNT - EXIT_FRAME_EPSILON) / eTeleporter[TELEPORTER_EXIT_FRAMERATE], "teleportExitHide", iEnt)
}

public teleportExitHide(iEnt)
{
    if ( pev_valid(iEnt) )
        set_pev(iEnt, pev_renderamt, 0.0)
}

stock teleportExitBeam(eTeleporter[TELEPORTER])
{
    new Float:fEnd[3], Float:fDir[3], Float:fLength, iCount

    iCount = random_num(eTeleporter[TELEPORTER_EXIT_BEAM_COUNT][0], eTeleporter[TELEPORTER_EXIT_BEAM_COUNT][1])
    for ( new i = 0; i < iCount; i ++ )
    {
        fDir[0] = random_float(-1.0, 1.0)
        fDir[1] = random_float(-1.0, 1.0)
        fDir[2] = random_float(EXIT_BEAM_DIRECTION_DOWN_MIN, 1.0)
        xs_vec_normalize(fDir, fDir)

        fLength = random_float(eTeleporter[TELEPORTER_EXIT_BEAM_LENGTH][0], eTeleporter[TELEPORTER_EXIT_BEAM_LENGTH][1])
        xs_vec_add_scaled(eTeleporter[TELEPORTER_ORIGIN_EXIT], fDir, fLength, fEnd)
        message_begin_f(MSG_PVS, SVC_TEMPENTITY, eTeleporter[TELEPORTER_ORIGIN_EXIT])
        write_byte(TE_BEAMPOINTS)
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN_EXIT][0])
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN_EXIT][1])
        write_coord_f(eTeleporter[TELEPORTER_ORIGIN_EXIT][2])
        write_coord_f(fEnd[0])
        write_coord_f(fEnd[1])
        write_coord_f(fEnd[2])
        write_short(eTeleporter[TELEPORTER_BEAM])
        write_byte(0)
        write_byte(0)
        write_byte(random_num(eTeleporter[TELEPORTER_EXIT_BEAM_LIFE][0], eTeleporter[TELEPORTER_EXIT_BEAM_LIFE][1]))
        write_byte(random_num(eTeleporter[TELEPORTER_EXIT_BEAM_WIDTH][0], eTeleporter[TELEPORTER_EXIT_BEAM_WIDTH][1]))
        write_byte(random_num(eTeleporter[TELEPORTER_EXIT_BEAM_NOISE][0], eTeleporter[TELEPORTER_EXIT_BEAM_NOISE][1]))
        write_byte(eTeleporter[TELEPORTER_EXIT_BEAM_COLOR][0])
        write_byte(eTeleporter[TELEPORTER_EXIT_BEAM_COLOR][1])
        write_byte(eTeleporter[TELEPORTER_EXIT_BEAM_COLOR][2])
        write_byte(eTeleporter[TELEPORTER_EXIT_BEAM_ALPHA])
        write_byte(0)
        message_end()
    }
}

stock teleporterSetBox(eTeleporter[TELEPORTER])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eTeleporter[TELEPORTER_ANGLES][0] = -eTeleporter[TELEPORTER_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eTeleporter[TELEPORTER_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eTeleporter[TELEPORTER_MINS])
    xs_vec_copy(fMaxs, eTeleporter[TELEPORTER_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock teleporterSetOffset(eTeleporter[TELEPORTER])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eTeleporter[TELEPORTER_MINS][0]
    fGaps[1] = eTeleporter[TELEPORTER_MAXS][0]
    fGaps[2] = -eTeleporter[TELEPORTER_MINS][1]
    fGaps[3] = eTeleporter[TELEPORTER_MAXS][1]
    fGaps[4] = -eTeleporter[TELEPORTER_MINS][2]
    fGaps[5] = eTeleporter[TELEPORTER_MAXS][2]

    if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eTeleporter[TELEPORTER_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eTeleporter[TELEPORTER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eTeleporter[TELEPORTER_ID], 0)
        get_tr2(0, TR_vecEndPos, eTeleporter[TELEPORTER_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eTeleporter[TELEPORTER_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eTeleporter[TELEPORTER_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eTeleporter[TELEPORTER_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eTeleporter[TELEPORTER_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eTeleporter[TELEPORTER_ORIGIN], fVec1, eTeleporter[TELEPORTER_ORIGIN])
        }
    }
}

stock teleporterSetSeq(iEnt, Float:fFrameRate, iSequence)
{
    set_pev(iEnt, pev_sequence, iSequence)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFrameRate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock teleporterSetSize(eTeleporter[TELEPORTER])
{
    teleporterSelect(eTeleporter, TARGET_CLEAR, false)
    engfunc(EngFunc_SetOrigin, eTeleporter[TELEPORTER_ID], eTeleporter[TELEPORTER_ORIGIN])
    set_pev(eTeleporter[TELEPORTER_ID], pev_angles, eTeleporter[TELEPORTER_ANGLES])
    set_pev(eTeleporter[TELEPORTER_ID], pev_solid, eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eTeleporter[TELEPORTER_ID], pev_movetype, MOVETYPE_NONE)

    eTeleporter[TELEPORTER_ANGLES][0] = -eTeleporter[TELEPORTER_ANGLES][0]
    engfunc(EngFunc_SetSize, eTeleporter[TELEPORTER_ID], eTeleporter[TELEPORTER_MINS], eTeleporter[TELEPORTER_MAXS])
    engfunc(EngFunc_GetAttachment, eTeleporter[TELEPORTER_ID], 0, eTeleporter[TELEPORTER_ORIGIN_BEAM_START], NULL_VECTOR)
    engfunc(EngFunc_GetAttachment, eTeleporter[TELEPORTER_ID], 1, eTeleporter[TELEPORTER_ORIGIN_BEAM_END], NULL_VECTOR)

    teleportCreateEnter(eTeleporter)
    teleporterCreateGlow(eTeleporter)
    ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_AMBIENT])), eTeleporter[TELEPORTER_SOUND_AMBIENT_CURRENT], charsmax(eTeleporter[TELEPORTER_SOUND_AMBIENT_CURRENT]))
}

stock teleporterSetState(eTeleporter[TELEPORTER])
{
    if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW )
    {
        set_pev(eTeleporter[TELEPORTER_ID], pev_solid, SOLID_BBOX)
        set_pev(eTeleporter[TELEPORTER_ENTER], pev_solid, SOLID_TRIGGER)
        teleporterSelect(eTeleporter, TARGET_CLEAR)

        if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_SOUND )
        {
            if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE )
            {
                if ( !(eTeleporter[TELEPORTER_FLAGS] & FLAG_PLAYING) )
                {
                    eTeleporter[TELEPORTER_FLAGS] |= FLAG_PLAYING
                    engfunc(EngFunc_EmitAmbientSound, eTeleporter[TELEPORTER_ID], CHAN_ITEM, eTeleporter[TELEPORTER_SOUND_AMBIENT_CURRENT], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
                }
            }
            else
            {
                if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_PLAYING )
                {
                    eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_PLAYING
                    engfunc(EngFunc_EmitAmbientSound, eTeleporter[TELEPORTER_ID], CHAN_ITEM, eTeleporter[TELEPORTER_SOUND_AMBIENT_CURRENT], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
                }
            }
        }
    }
    else
    {
        set_pev(eTeleporter[TELEPORTER_ID], pev_solid, SOLID_NOT)
        set_pev(eTeleporter[TELEPORTER_ENTER], pev_solid, SOLID_NOT)
        teleporterSelect(eTeleporter, TARGET_HIDE)

        if ( eTeleporter[TELEPORTER_FLAGS] & (FLAG_PLAYING | FLAG_SOUND) == (FLAG_PLAYING | FLAG_SOUND) )
        {
            eTeleporter[TELEPORTER_FLAGS] &= ~FLAG_PLAYING
            engfunc(EngFunc_EmitAmbientSound, eTeleporter[TELEPORTER_ID], CHAN_ITEM, eTeleporter[TELEPORTER_SOUND_AMBIENT_CURRENT], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
        }
    }
}

stock teleporterSelect(eTeleporter[TELEPORTER], iAction, bool:bTeleportExit = true)
{
    new iRenderColor[3]
    if ( iAction == TARGET_SELECT )
    {
        if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE )  { iRenderColor[0] = 0;   iRenderColor[1] = 255;     iRenderColor[2] = 0; }
        else                                                { iRenderColor[0] = 255; iRenderColor[1] = 0;       iRenderColor[2] = 0; }

        entitySetRendering(eTeleporter[TELEPORTER_ID], kRenderFxGlowShell, iRenderColor[0], iRenderColor[1], iRenderColor[2], kRenderTransAlpha, 16)
        entitySetRendering(eTeleporter[TELEPORTER_EXIT], kRenderFxGlowShell, eTeleporter[TELEPORTER_EXIT_COLOR][0], eTeleporter[TELEPORTER_EXIT_COLOR][1], eTeleporter[TELEPORTER_EXIT_COLOR][2], kRenderTransAdd, 64)
        entitySetRendering(eTeleporter[TELEPORTER_GLOW][0], kRenderFxGlowShell, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, 64)
        entitySetRendering(eTeleporter[TELEPORTER_GLOW][1], kRenderFxGlowShell, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, 64)
    }
    else if ( iAction == TARGET_GHOST )
    {
        entitySetRendering(eTeleporter[TELEPORTER_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, TELEPORTER_GHOST_ALPHA)

        if ( bTeleportExit )
        {
            entitySetRendering(eTeleporter[TELEPORTER_GLOW][0], kRenderFxNone, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, TELEPORTER_GHOST_ALPHA)
            entitySetRendering(eTeleporter[TELEPORTER_GLOW][1], kRenderFxNone, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, TELEPORTER_GHOST_ALPHA)
            entitySetRendering(eTeleporter[TELEPORTER_EXIT], kRenderFxGlowShell, eTeleporter[TELEPORTER_EXIT_COLOR][0], eTeleporter[TELEPORTER_EXIT_COLOR][1], eTeleporter[TELEPORTER_EXIT_COLOR][2], kRenderTransAdd, 0)
        }
    }
    else if ( iAction == TARGET_HIDE )
    {
        entitySetRendering(eTeleporter[TELEPORTER_ID], kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 0)
        entitySetRendering(eTeleporter[TELEPORTER_GLOW][0], kRenderFxGlowShell, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, 0)
        entitySetRendering(eTeleporter[TELEPORTER_GLOW][1], kRenderFxGlowShell, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, 0)
        entitySetRendering(eTeleporter[TELEPORTER_EXIT], kRenderFxGlowShell, eTeleporter[TELEPORTER_EXIT_COLOR][0], eTeleporter[TELEPORTER_EXIT_COLOR][1], eTeleporter[TELEPORTER_EXIT_COLOR][2], kRenderTransAdd, 0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        entitySetRendering(eTeleporter[TELEPORTER_ID], kRenderFxNone, 255, 255, 255, kRenderNormal, 255)

        if ( bTeleportExit )
        {
            entitySetRendering(eTeleporter[TELEPORTER_GLOW][0], kRenderFxNone, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE ? eTeleporter[TELEPORTER_GLOW_ALPHA] : 0)
            entitySetRendering(eTeleporter[TELEPORTER_GLOW][1], kRenderFxNone, eTeleporter[TELEPORTER_GLOW_COLOR][0], eTeleporter[TELEPORTER_GLOW_COLOR][1], eTeleporter[TELEPORTER_GLOW_COLOR][2], kRenderTransAdd, eTeleporter[TELEPORTER_FLAGS] & FLAG_ACTIVE ? eTeleporter[TELEPORTER_GLOW_ALPHA] : 0)
            entitySetRendering(eTeleporter[TELEPORTER_EXIT], kRenderFxGlowShell, eTeleporter[TELEPORTER_EXIT_COLOR][0], eTeleporter[TELEPORTER_EXIT_COLOR][1], eTeleporter[TELEPORTER_EXIT_COLOR][2], kRenderTransAdd, 0)
        }
    }
}

stock teleporterReset()
{
    new eTeleporter[TELEPORTER]
    for ( new i = 0; i < g_iTeleporter; i ++ )
    {
        ArrayGetArray(g_aTeleporter, i, eTeleporter)
        eTeleporter[TELEPORTER_NEXT_COOLDOWN] = 0.0
        ArraySetArray(g_aTeleporter, i, eTeleporter)
    }
}

stock teleporterSound(iEnt, iSound, bool:bPlayer = true)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, CHAN_ITEM, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}



stock teleporterGet(eTeleporter[TELEPORTER], iEnt)
{
    if ( !isTeleporter(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, TELEPORTER_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iTeleporter )
        return -1

    ArrayGetArray(g_aTeleporter, iItem, eTeleporter)
    return iItem
}

stock bool:isTeleporter(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == TELEPORTER_KEY
}

stock teleporterKill(eTeleporter[TELEPORTER])
{
    if ( pev_valid(eTeleporter[TELEPORTER_ID]) )
        set_pev(eTeleporter[TELEPORTER_ID], pev_flags, pev(eTeleporter[TELEPORTER_ID], pev_flags) | FL_KILLME)

    if ( pev_valid(eTeleporter[TELEPORTER_ENTER]) )
        set_pev(eTeleporter[TELEPORTER_ENTER], pev_flags, pev(eTeleporter[TELEPORTER_ENTER], pev_flags) | FL_KILLME)

    if ( pev_valid(eTeleporter[TELEPORTER_GLOW][0]) )
        set_pev(eTeleporter[TELEPORTER_GLOW][0], pev_flags, pev(eTeleporter[TELEPORTER_GLOW][0], pev_flags) | FL_KILLME)

    if ( pev_valid(eTeleporter[TELEPORTER_GLOW][1]) )
        set_pev(eTeleporter[TELEPORTER_GLOW][1], pev_flags, pev(eTeleporter[TELEPORTER_GLOW][1], pev_flags) | FL_KILLME)

    if ( pev_valid(eTeleporter[TELEPORTER_EXIT]) )
        set_pev(eTeleporter[TELEPORTER_EXIT], pev_flags, pev(eTeleporter[TELEPORTER_EXIT], pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            if ( !g_bFileWasRead )
                precache_model(szValue)

            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_TELEPORTER_ACTION] )
    {
        new eTeleporter[TELEPORTER]
        for ( new i = 0; i < g_iTeleporter; i ++ )
        {
            ArrayGetArray(g_aTeleporter, i, eTeleporter)
            if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW )
                continue

            teleporterSelect(eTeleporter, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_TELEPORTER_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_TELEPORTER_ACTION] )
    {
        new eTeleporter[TELEPORTER]
        for ( new i = 0; i < g_iTeleporter; i ++ )
        {
            ArrayGetArray(g_aTeleporter, i, eTeleporter)
            if ( eTeleporter[TELEPORTER_FLAGS] & FLAG_SHOW )
                continue

            teleporterSelect(eTeleporter, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_TELEPORTER_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
    EnableHamForward(g_iFwdKilled)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
    DisableHamForward(g_iFwdKilled)
}

stock EnableTeleporter()
{
    EnableHamForward(g_iFwdTouch)
}

stock DisableTeleporter()
{
    DisableHamForward(g_iFwdTouch)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}

stock entitySetRendering(iEntity, iRenderFx, iRed, iGreen, iBlue, iRenderMode, iRenderAmt)
{
    new Float:fRenderColor[3]
    fRenderColor[0] = float(iRed)
    fRenderColor[1] = float(iGreen)
    fRenderColor[2] = float(iBlue)

    set_pev(iEntity, pev_renderfx, iRenderFx)
    set_pev(iEntity, pev_rendercolor, fRenderColor)
    set_pev(iEntity, pev_rendermode, iRenderMode)
    set_pev(iEntity, pev_renderamt, float(iRenderAmt))
}
