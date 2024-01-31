;/**
; * @file    zingzong.h
; * @author  Benjamin Gerard AKA Ben^OVR
; * @date    2017-07-04
; * @brief   zingzong public API.
; */
;#define ZINGZONG_H


;/**
; * Integer types the platform prefers matching our requirements.
; */
;typedef	 int_fast8_t  zz_i8_t;
;typedef uint_fast8_t  zz_u8_t;
;typedef	 int_fast16_t zz_i16_t;
;typedef uint_fast16_t zz_u16_t;
;typedef	 int_fast32_t zz_i32_t;




;/**
; * Zingzong error codes.
; */
Enumeration
	#ZZ_OK		   ;/**< (0) No error.                       */
	#ZZ_ERR		   ;/**< (1) Unspecified error.              */
	#ZZ_EARG		   ;/**< (2) Argument error.                 */
	#ZZ_ESYS		   ;/**< (3) System error (I/O memory ...). */
	#ZZ_EINP		   ;/**< (4) Problem with input.             */
	#ZZ_EOUT		   ;/**< (5) Problem with output.            */
	#ZZ_ESNG		   ;/**< (6) Song error.                     */
	#ZZ_ESET		   ;/**< (7) Voice set error                 */
	#ZZ_EPLA		   ;/**< (8) Player error.                   */
	#ZZ_EMIX		   ;/**< (9) Mixer error.                    */
	#ZZ_666 = 66		   ;/**< Internal error.                     */
EndEnumeration

;/**
; * Known (but not always supported) Quartet file format.
; */
Enumeration
	#ZZ_FORMAT_UNKNOWN	       ;/**< Not yet determined (must be 0)  */
	#ZZ_FORMAT_4V		       ;/**< Original Atari ST song.         */
	#ZZ_FORMAT_BUNDLE = 64       ;/**< Next formats are bundles.       */
	#ZZ_FORMAT_4Q		       ;/**< Single song bundle (MUG UK ?).  */
	#ZZ_FORMAT_QUAR	       ;/**< Multi song bundle (SC68).       */
EndEnumeration

;/**
; * Mixer identifiers.
; */
Enumeration
	#ZZ_MIXER_XTN = 254	       ;/**< External mixer.                 */
	#ZZ_MIXER_DEF = 255	       ;/**< Default mixer id.               */
	#ZZ_MIXER_ERR = #ZZ_MIXER_DEF  ;/**< Error (alias for ZZ_MIXER_DEF). */
EndEnumeration

;/**
; * Stereo channel mapping.
; */
Enumeration
	#ZZ_MAP_ABCD			       ;/**< (0) Left:A+B Right:C+D. */
	#ZZ_MAP_ACBD			       ;/**< (1) Left:A+C Right:B+D. */
	#ZZ_MAP_ADBC			       ;/**< (2) Left:A+D Right:B+C. */
EndEnumeration

;/**
; * Sampler quality.
; */
Enumeration
	#ZZ_FQ = 1				;/**< (1) Fastest quality. */
	#ZZ_LQ				;/**< (2) Low quality.     */
	#ZZ_MQ				;/**< (3) Medium quality.  */
	#ZZ_HQ					;/**< (4) High quality.    */
EndEnumeration

;typedef zz_i8_t zz_err_t;
;typedef struct vfs_s   * zz_vfs_t;
;typedef struct vset_s  * zz_vset_t;
;typedef struct song_s  * zz_song_t;
;typedef struct core_s  * zz_core_t;
;typedef struct play_s  * zz_play_t;
;typedef struct mixer_s * zz_mixer_t;
;typedef const struct zz_vfs_dri_s * zz_vfs_dri_t;
;typedef zz_err_t (*zz_guess_t)(zz_play_t const, const char *);
;typedef struct zz_info_s zz_info_t;

;/**
; * zingzong info.
; */
Structure  fmt;			    ;/**< format info.               */
	num.a					;/**< format (@see zz_format_e). */
	str.l					;/**< format string.             */
EndStructure
Structure  len;			    ;/**< replay info.               */
	rate.i					;/**< player tick rate (200hz).  */
	ms.i					;/**< song duration in ms.       */
EndStructure
Structure  mix;		       ;/**< mixer related info.             */
	spr.i					;/**< sampling rate.                  */
	num.a					;/**< mixer identifier.               */
	_Map.a					;/**< channel mapping (ZZ_MAP_*).     */
	lr8.i					;/**< 0:normal 128:center 256:invert. */
						
	name.l					;/**< mixer name or "".               */
	desc.l					;/**< mixer description or "".        */
EndStructure
Structure set
	uri.l					;/**< URI or path.               */
	khz.i					;/**< sampling rate reported.    */
EndStructure
Structure sng
	uri.l					;/**< URI or path.               */
	khz.i					;/**< sampling rate reported.    */
EndStructure
Structure  tag;			    ;/**< meta tags.                 */
	album.l					;/**< album or "".               */
	title.l					;/**< title or "".               */
	artist.l					;/**< artist or "".              */
	ripper.l					;/**< ripper or "".              */
EndStructure
Structure zz_info_s
	*fmt.fmt
	*len.len
	*mix.mix
	*set.set
	*sng.sng
	*tag.tag
						
  ;/** mixer info. */
EndStructure;


;/* **********************************************************************
; *
; * Low level API (core)
; *
; * **********************************************************************/


;/**
; * Get zingzong version string.
; *
; * @retval "zingzong MAJOR.MINOR.PATCH.TWEAK"
; */
;const char * zz_core_version(void);


;/**
; * Mute and ignore voices.
; * - LSQ bits (0~3) are ignored channels.
; * - MSQ bits (4~7) are muted channels.
; *
; * @param  play  player instance
; * @param  clr   clear these bits
; * @param  set   set these bits
; * @return old bits
; */
;uint8_t zz_core_mute(zz_core_t K, uint8_t clr, uint8_t set);


;/**
; * Init core player.
; */
;zz_err_t zz_core_init(zz_core_t core, zz_mixer_t mixer, zz_u32_t spr);


;/**
; * Kill core player.
; */
;void zz_core_kill(zz_core_t core);


;/**
; * Play one tick.
; */
;zz_err_t zz_core_tick(zz_core_t const core);


;/**
; * Play one tick by calling zz_core_tick() and generate audio.
; */
;zz_i16_t zz_core_play(zz_core_t core, void * pcm, zz_i16_t n);


;/**
; * Set channel blending.
; */
;zz_u32_t zz_core_blend(zz_core_t core, zz_u8_t map, zz_u16_t lr8);


;/* **********************************************************************
; *
; * Logging and memory allocation
; *
; * **********************************************************************/

;/**
; * Log level (first parameter of zz_log_t function).
; */
Enumeration
	#ZZ_LOG_ERR				;/**< Log error.   */
	#ZZ_LOG_WRN				;/**< Log warning. */
	#ZZ_LOG_INF				;/**< Log info.    */
	#ZZ_LOG_DBG				;/**< Log debug.   */
EndEnumeration

;/**
; * Zingzong log function type (printf-like).
; */
;typedef void (*zz_log_t)(zz_u8_t,void *,const char *,va_list);


;/**
; * Get/Set zingzong active logging channels.
; *
; * @param  clr  bit mask of channels to disable).
; * @param  set  bit mask of channels to en able).
; * @return previous active logging channel mask.
; */
;zz_u8_t zz_log_bit(const zz_u8_t clr, const zz_u8_t set);


;/**
; * Set Zingzong log function.
; *
; * @param func  pointer to the new log function (0: to disable all).
; */
;void zz_log_fun(zz_log_t func, void * user);

;/**
; * Memory allocation function types.
; */
;typedef void * (*zz_new_t)(zz_u32_t); ;/**< New memory function type. */
;typedef void   (*zz_del_t)(void *);   ;/**< Del memory function type. */


;/**
; * Set Zingzong memory management function.
; *
; * @param  newf pointer to the memory allocation function.
; * @param  delf pointer to the memory free function.
; */
;void zz_mem(zz_new_t newf, zz_del_t delf);


;/**
; * Create a new player instance.
; *
; * @param pplay pointer to player instance
; * @return error code
; * @retval ZZ_OK(0) on success
; */
;zz_err_t zz_new(zz_play_t * pplay);


;/**
; * Delete player instance.
; * @param pplay pointer to player instance
; */
;void zz_del(zz_play_t * pplay);


;/* **********************************************************************
; *
; * High level API
; *
; * **********************************************************************/


;/**
; * Load quartet song and voice-set.
; *
; * @param  play  player instance
; * @param  song  song URI or path ("": skip).
; * @param  vset  voice-set URI or path (0:guess "":skip)
; * @param  pfmt  points to a variable to store file format (can be 0).
; * @return error code
; * @retval ZZ_OK(0) on success
; */
zz_err_t zz_load(zz_play_t const play,
		 const char * song, const char * vset,
;zz_err_t zz_load(zz_play_t const play,		 const char * song, const char * vset,		 zz_u8_t * pfmt);


;/**
; * Close player (release allocated resources).
; *
; * @param  play  player instance
; * @return error code
; * @retval ZZ_OK(0) on success
; */
;zz_err_t zz_close(zz_play_t const play);


;/**
; * Get player info.
; *
; * @param  play  player instance
; * @param  info  info filled by zz_info().
; * @return error code
; * @retval ZZ_OK(0) on success
; */
;zz_err_t zz_info(zz_play_t play, zz_info_t * pinfo);


;/**
; * Init player.
; *
; * @param  play   player instance
; * @param  rate   player tick rate (0:default)
; * @param  ms     playback duration (0:infinite, ZZ_EOF:measured)
; * @return error code
; * @retval ZZ_OK(0) on success
; */
;zz_err_t zz_init(zz_play_t play, zz_u16_t rate, zz_u32_t ms);


;/**
; * Setup mixer.
; *
; * @param  play   player instance
; * @param  mixer  mixer-id
; * @param  spr    sampling rate or quality
; * @return error code
; * @retval ZZ_OK(0) on success
; * @notice Call zz_init() before zz_setup().
; */
;zz_err_t zz_setup(zz_play_t play, zz_u8_t mixer, zz_u32_t spr);


;/**
; * Play a tick.
; *
; * @param  play   player instance
; * @return error code
; * @retval ZZ_OK(0) on success
; * @notice zz_tick() is called by zz_play().
; */
;zz_err_t zz_tick(zz_play_t play);


;/**
; * Play.
; *
; * @param  play  player instance
; * @param  pcm   pcm buffer (format might depend on mixer).
; * @param  n     >0: number of pcm to fill
; *                0: get number of pcm to complete the tick.
; *               <0: complete the tick but not more than -n pcm.
; *
; * @return number of pcm.
; * @retval 0 play is over
; * @retval >0 number of pcm
; * @retval <0 -error code
; */
;zz_i16_t zz_play(zz_play_t play, void * pcm, zz_i16_t n);


;/**
; * Get current play position (in ms).
; * @return number of millisecond
; * @retval ZZ_EOF on error
; */
;zz_u32_t zz_position(zz_play_t play);


;/**
; * Get info mixer info.
; *
; * @param  id     mixer identifier (first is 0)
; * @param  pname  receive a pointer to the mixer name
; * @param  pdesc  receive a pointer to the mixer description
; * @return mixer-id (usually id unless id is ZZ_MIXER_DEF)
; * @retval ZZ_MIXER_DEF on error
; *
; * @notice The zz_mixer_info() function can be use to enumerate all
; *         available mixers.
; */
;zz_u8_t zz_mixer_info(zz_u8_t id, const char **pname, const char **pdesc);

;/**
; * Channels re-sampler and mixer interface.
; */
Prototype.i Prototype_init(pram_a,pram_b.i) 
Prototype Prototype_free(pram_a) 
Prototype.l Prototype_push(pram_a,pram_b,pram_c.l) 
Structure mixer_s
	name.l					;/**< friendly name and method. */
	desc.l					;/**< mixer brief description.  */
						
						;/** Init mixer function. */
	_init.Prototype_init					
						
						;/** Release mixer function. */
	_free.Prototype_free					
						
						;/** Push PCM function. */
	_push.Prototype_push					
EndStructure;

;/* **********************************************************************
; *
; * VFS
; *
; * **********************************************************************/

Enumeration
#ZZ_SEEK_SET
#ZZ_SEEK_CUR
#ZZ_SEEK_END
 
 

EndEnumeration

;#define ZZ_EOF ((zz_u32_t)-1)

;/**
; * Virtual filesystem driver.
; */
Prototype.i Prototype_reg(pram_a.i) 
Prototype.i Prototype_unreg(pram_a.i) 
Prototype.l Prototype_ismine(pram_a.l) 
Prototype.l Prototype_new(pram_a.l,pram_b.l) 
Prototype Prototype_del(pram_a) 
Prototype Prototype_uri(pram_a) 
Prototype Prototype_open(pram_a) 
Prototype Prototype_close(pram_a) 
Prototype.i Prototype_read(pram_a,pram_b,pram_c.i) 
Prototype Prototype_tell(pram_a) 
Prototype Prototype_size(pram_a) 
Prototype.a Prototype_seek(pram_a,pram_b.i,pram_c.a) 
Structure zz_vfs_dri_s
	name.l					;/**< friendly name.      */
	_reg.Prototype_reg					;/**< register driver.    */
	_unreg.Prototype_unreg					;/**< un-register driver. */
	_ismine.Prototype_ismine					;/**< is mine.            */
	_new.Prototype_new					;/**< create VFS.         */
	_del.Prototype_del					;/**< destroy VFS.        */
	const					
	_uri.Prototype_uri					;/**< get URI.       */
	_open.Prototype_open					;/**< open.          */
	_close.Prototype_close					;/**< close.         */
	_read.Prototype_read					;/**< read.          */
	_tell.Prototype_tell					;/**< get position.  */
	_size.Prototype_size					;/**< get size.      */
	_seek.Prototype_seek					;/**< offset,whence. */
EndStructure;

;/**
; * Common (inherited) part to all VFS instance.
; */
Structure vfs_s
	dri.i					;/**< pointer to the VFS driver. */
	err.i					;/**< last error number.         */
	pb_pos.i					;/**< push-back position.        */
	pb_len.i					;/**< push-back length.          */
	pb_buf.i[16]					;/**< push-back buffer.          */
EndStructure;


;/**
; * Register a VFS driver.
; * @param  dri  VFS driver
; * @return error code
; * @retval ZZ_OK(0) on success
; */
;zz_err_t zz_vfs_add(zz_vfs_dri_t dri);


;/**
; * Unregister a VFS driver.
; * @param  dri  VFS driver
; * @return error code
; * @retval ZZ_OK(0) on success
; */
;zz_err_t zz_vfs_del(zz_vfs_dri_t dri);

PrototypeC.l zz_core_version() : Global zz_core_version.zz_core_version
PrototypeC.i zz_core_mute(K.l,clr.i,set.i) : Global zz_core_mute.zz_core_mute
PrototypeC.l zz_core_init(core.l,mixer,spr.i) : Global zz_core_init.zz_core_init
PrototypeC zz_core_kill(core.l) : Global zz_core_kill.zz_core_kill
PrototypeC.l zz_core_tick(core) : Global zz_core_tick.zz_core_tick
PrototypeC.l zz_core_play(core.l,*pcm,n.l) : Global zz_core_play.zz_core_play
PrototypeC.i zz_core_blend(core.l,_Map,lr8.i) : Global zz_core_blend.zz_core_blend
PrototypeC.a zz_log_bit(clr,set) : Global zz_log_bit.zz_log_bit
PrototypeC zz_log_fun(func,*user) : Global zz_log_fun.zz_log_fun
PrototypeC zz_mem(newf,delf) : Global zz_mem.zz_mem
PrototypeC.l zz_new(*pplay) : Global zz_new.zz_new
PrototypeC zz_del(*pplay) : Global zz_del.zz_del
PrototypeC.l zz_load(play,*song.l,*vset.l,*pfmt) : Global zz_load.zz_load
PrototypeC.l zz_close(play) : Global zz_close.zz_close
PrototypeC.l zz_info(play,*pinfo) : Global zz_info.zz_info
PrototypeC.l zz_init(play,rate.i,ms.i) : Global zz_init.zz_init
PrototypeC.l zz_setup(play,mixer.a,spr.i) : Global zz_setup.zz_setup
PrototypeC.l zz_tick(play) : Global zz_tick.zz_tick
PrototypeC.l zz_play(play,*pcm,n.l) : Global zz_play.zz_play
PrototypeC.i zz_position(play) : Global zz_position.zz_position
PrototypeC.a zz_mixer_info(id.a,*pname.l,*pdesc.l) : Global zz_mixer_info.zz_mixer_info
PrototypeC.l zz_vfs_add(dri.i) : Global zz_vfs_add.zz_vfs_add
PrototypeC.l zz_vfs_del(dri.i) : Global zz_vfs_del.zz_vfs_del

Procedure.l <%PRJ>_OpenLibrary(library.s)
  dll = OpenLibrary(#PB_Any,library)
  If dll_plugin
	zz_core_version = GetFunction(dll,"zz_core_version")
	zz_core_mute = GetFunction(dll,"zz_core_mute")
	zz_core_init = GetFunction(dll,"zz_core_init")
	zz_core_kill = GetFunction(dll,"zz_core_kill")
	zz_core_tick = GetFunction(dll,"zz_core_tick")
	zz_core_play = GetFunction(dll,"zz_core_play")
	zz_core_blend = GetFunction(dll,"zz_core_blend")
	zz_log_bit = GetFunction(dll,"zz_log_bit")
	zz_log_fun = GetFunction(dll,"zz_log_fun")
	zz_mem = GetFunction(dll,"zz_mem")
	zz_new = GetFunction(dll,"zz_new")
	zz_del = GetFunction(dll,"zz_del")
	zz_load = GetFunction(dll,"zz_load")
	zz_close = GetFunction(dll,"zz_close")
	zz_info = GetFunction(dll,"zz_info")
	zz_init = GetFunction(dll,"zz_init")
	zz_setup = GetFunction(dll,"zz_setup")
	zz_tick = GetFunction(dll,"zz_tick")
	zz_play = GetFunction(dll,"zz_play")
	zz_position = GetFunction(dll,"zz_position")
	zz_mixer_info = GetFunction(dll,"zz_mixer_info")
	zz_vfs_add = GetFunction(dll,"zz_vfs_add")
	zz_vfs_del = GetFunction(dll,"zz_vfs_del")
  Else
    ProcedureReturn #False
  EndIf
  ProcedureReturn dll_plugin
EndProcedure

