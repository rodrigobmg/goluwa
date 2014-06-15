return [[
 int archive_version_number(void);
 const char * archive_version_string(void);
 const char * archive_version_details(void);
struct archive;
struct archive_entry;
typedef size_t archive_read_callback(struct archive *,
       void *_client_data, const void **_buffer);
typedef long long archive_skip_callback(struct archive *,
       void *_client_data, long long request);
typedef long long archive_seek_callback(struct archive *,
    void *_client_data, long long offset, int whence);
typedef size_t archive_write_callback(struct archive *,
       void *_client_data,
       const void *_buffer, size_t _length);
typedef int archive_open_callback(struct archive *, void *_client_data);
typedef int archive_close_callback(struct archive *, void *_client_data);
typedef int archive_switch_callback(struct archive *, void *_client_data1,
       void *_client_data2);
 struct archive *archive_read_new(void);
 int archive_read_support_compression_all(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_bzip2(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_compress(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_gzip(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_lzip(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_lzma(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_none(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_program(struct archive *,
       const char *command) __attribute__((deprecated));
 int archive_read_support_compression_program_signature
  (struct archive *, const char *,
   const void * , size_t) __attribute__((deprecated));
 int archive_read_support_compression_rpm(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_uu(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_compression_xz(struct archive *)
  __attribute__((deprecated));
 int archive_read_support_filter_all(struct archive *);
 int archive_read_support_filter_bzip2(struct archive *);
 int archive_read_support_filter_compress(struct archive *);
 int archive_read_support_filter_gzip(struct archive *);
 int archive_read_support_filter_grzip(struct archive *);
 int archive_read_support_filter_lrzip(struct archive *);
 int archive_read_support_filter_lzip(struct archive *);
 int archive_read_support_filter_lzma(struct archive *);
 int archive_read_support_filter_lzop(struct archive *);
 int archive_read_support_filter_none(struct archive *);
 int archive_read_support_filter_program(struct archive *,
       const char *command);
 int archive_read_support_filter_program_signature
  (struct archive *, const char * ,
        const void * , size_t);
 int archive_read_support_filter_rpm(struct archive *);
 int archive_read_support_filter_uu(struct archive *);
 int archive_read_support_filter_xz(struct archive *);
 int archive_read_support_format_7zip(struct archive *);
 int archive_read_support_format_all(struct archive *);
 int archive_read_support_format_ar(struct archive *);
 int archive_read_support_format_by_code(struct archive *, int);
 int archive_read_support_format_cab(struct archive *);
 int archive_read_support_format_cpio(struct archive *);
 int archive_read_support_format_empty(struct archive *);
 int archive_read_support_format_gnutar(struct archive *);
 int archive_read_support_format_iso9660(struct archive *);
 int archive_read_support_format_lha(struct archive *);
 int archive_read_support_format_mtree(struct archive *);
 int archive_read_support_format_rar(struct archive *);
 int archive_read_support_format_raw(struct archive *);
 int archive_read_support_format_tar(struct archive *);
 int archive_read_support_format_xar(struct archive *);
 int archive_read_support_format_zip(struct archive *);
 int archive_read_support_format_zip_streamable(struct archive *);
 int archive_read_support_format_zip_seekable(struct archive *);
 int archive_read_set_format(struct archive *, int);
 int archive_read_append_filter(struct archive *, int);
 int archive_read_append_filter_program(struct archive *,
    const char *);
 int archive_read_append_filter_program_signature
    (struct archive *, const char *, const void * , size_t);
 int archive_read_set_open_callback(struct archive *,
    archive_open_callback *);
 int archive_read_set_read_callback(struct archive *,
    archive_read_callback *);
 int archive_read_set_seek_callback(struct archive *,
    archive_seek_callback *);
 int archive_read_set_skip_callback(struct archive *,
    archive_skip_callback *);
 int archive_read_set_close_callback(struct archive *,
    archive_close_callback *);
 int archive_read_set_switch_callback(struct archive *,
    archive_switch_callback *);
 int archive_read_set_callback_data(struct archive *, void *);
 int archive_read_set_callback_data2(struct archive *, void *,
    unsigned int);
 int archive_read_add_callback_data(struct archive *, void *,
    unsigned int);
 int archive_read_append_callback_data(struct archive *, void *);
 int archive_read_prepend_callback_data(struct archive *, void *);
 int archive_read_open1(struct archive *);
 int archive_read_open(struct archive *, void *_client_data,
       archive_open_callback *, archive_read_callback *,
       archive_close_callback *);
 int archive_read_open2(struct archive *, void *_client_data,
       archive_open_callback *, archive_read_callback *,
       archive_skip_callback *, archive_close_callback *);
 int archive_read_open_filename(struct archive *,
       const char *_filename, size_t _block_size);
 int archive_read_open_filenames(struct archive *,
       const char **_filenames, size_t _block_size);
 int archive_read_open_filename_w(struct archive *,
       const wchar_t *_filename, size_t _block_size);
 int archive_read_open_file(struct archive *,
       const char *_filename, size_t _block_size) __attribute__((deprecated));
 int archive_read_open_memory(struct archive *,
       void * buff, size_t size);
 int archive_read_open_memory2(struct archive *a, void *buff,
       size_t size, size_t read_size);
 int archive_read_open_fd(struct archive *, int _fd,
       size_t _block_size);
 int archive_read_open_FILE(struct archive *, FILE *_file);
 int archive_read_next_header(struct archive *,
       struct archive_entry **);
 int archive_read_next_header2(struct archive *,
       struct archive_entry *);
 long long archive_read_header_position(struct archive *);
 int archive_read_has_encrypted_entries(struct archive *);
 int archive_read_format_capabilities(struct archive *);
 size_t archive_read_data(struct archive *,
        void *, size_t);
 long long archive_seek_data(struct archive *, long long, int);
 int archive_read_data_block(struct archive *a,
      const void **buff, size_t *size, long long *offset);
 int archive_read_data_skip(struct archive *);
 int archive_read_data_into_fd(struct archive *, int fd);
 int archive_read_set_format_option(struct archive *_a,
       const char *m, const char *o,
       const char *v);
 int archive_read_set_filter_option(struct archive *_a,
       const char *m, const char *o,
       const char *v);
 int archive_read_set_option(struct archive *_a,
       const char *m, const char *o,
       const char *v);
 int archive_read_set_options(struct archive *_a,
       const char *opts);
 int archive_read_extract(struct archive *, struct archive_entry *,
       int flags);
 int archive_read_extract2(struct archive *, struct archive_entry *,
       struct archive * );
 void archive_read_extract_set_progress_callback(struct archive *,
       void (*_progress_func)(void *), void *_user_data);
 void archive_read_extract_set_skip_file(struct archive *,
       long long, long long);
 int archive_read_close(struct archive *);
 int archive_read_free(struct archive *);
 int archive_read_finish(struct archive *) __attribute__((deprecated));
 struct archive *archive_write_new(void);
 int archive_write_set_bytes_per_block(struct archive *,
       int bytes_per_block);
 int archive_write_get_bytes_per_block(struct archive *);
 int archive_write_set_bytes_in_last_block(struct archive *,
       int bytes_in_last_block);
 int archive_write_get_bytes_in_last_block(struct archive *);
 int archive_write_set_skip_file(struct archive *,
    long long, long long);
 int archive_write_set_compression_bzip2(struct archive *)
  __attribute__((deprecated));
 int archive_write_set_compression_compress(struct archive *)
  __attribute__((deprecated));
 int archive_write_set_compression_gzip(struct archive *)
  __attribute__((deprecated));
 int archive_write_set_compression_lzip(struct archive *)
  __attribute__((deprecated));
 int archive_write_set_compression_lzma(struct archive *)
  __attribute__((deprecated));
 int archive_write_set_compression_none(struct archive *)
  __attribute__((deprecated));
 int archive_write_set_compression_program(struct archive *,
       const char *cmd) __attribute__((deprecated));
 int archive_write_set_compression_xz(struct archive *)
  __attribute__((deprecated));
 int archive_write_add_filter(struct archive *, int filter_code);
 int archive_write_add_filter_by_name(struct archive *,
       const char *name);
 int archive_write_add_filter_b64encode(struct archive *);
 int archive_write_add_filter_bzip2(struct archive *);
 int archive_write_add_filter_compress(struct archive *);
 int archive_write_add_filter_grzip(struct archive *);
 int archive_write_add_filter_gzip(struct archive *);
 int archive_write_add_filter_lrzip(struct archive *);
 int archive_write_add_filter_lzip(struct archive *);
 int archive_write_add_filter_lzma(struct archive *);
 int archive_write_add_filter_lzop(struct archive *);
 int archive_write_add_filter_none(struct archive *);
 int archive_write_add_filter_program(struct archive *,
       const char *cmd);
 int archive_write_add_filter_uuencode(struct archive *);
 int archive_write_add_filter_xz(struct archive *);
 int archive_write_set_format(struct archive *, int format_code);
 int archive_write_set_format_by_name(struct archive *,
       const char *name);
 int archive_write_set_format_7zip(struct archive *);
 int archive_write_set_format_ar_bsd(struct archive *);
 int archive_write_set_format_ar_svr4(struct archive *);
 int archive_write_set_format_cpio(struct archive *);
 int archive_write_set_format_cpio_newc(struct archive *);
 int archive_write_set_format_gnutar(struct archive *);
 int archive_write_set_format_iso9660(struct archive *);
 int archive_write_set_format_mtree(struct archive *);
 int archive_write_set_format_mtree_classic(struct archive *);
 int archive_write_set_format_pax(struct archive *);
 int archive_write_set_format_pax_restricted(struct archive *);
 int archive_write_set_format_raw(struct archive *);
 int archive_write_set_format_shar(struct archive *);
 int archive_write_set_format_shar_dump(struct archive *);
 int archive_write_set_format_ustar(struct archive *);
 int archive_write_set_format_v7tar(struct archive *);
 int archive_write_set_format_xar(struct archive *);
 int archive_write_set_format_zip(struct archive *);
 int archive_write_zip_set_compression_deflate(struct archive *);
 int archive_write_zip_set_compression_store(struct archive *);
 int archive_write_open(struct archive *, void *,
       archive_open_callback *, archive_write_callback *,
       archive_close_callback *);
 int archive_write_open_fd(struct archive *, int _fd);
 int archive_write_open_filename(struct archive *, const char *_file);
 int archive_write_open_filename_w(struct archive *,
       const wchar_t *_file);
 int archive_write_open_file(struct archive *, const char *_file)
  __attribute__((deprecated));
 int archive_write_open_FILE(struct archive *, FILE *);
 int archive_write_open_memory(struct archive *,
   void *_buffer, size_t _buffSize, size_t *_used);
 int archive_write_header(struct archive *,
       struct archive_entry *);
 size_t archive_write_data(struct archive *,
       const void *, size_t);
 size_t archive_write_data_block(struct archive *,
        const void *, size_t, long long);
 int archive_write_finish_entry(struct archive *);
 int archive_write_close(struct archive *);
 int archive_write_fail(struct archive *);
 int archive_write_free(struct archive *);
 int archive_write_finish(struct archive *) __attribute__((deprecated));
 int archive_write_set_format_option(struct archive *_a,
       const char *m, const char *o,
       const char *v);
 int archive_write_set_filter_option(struct archive *_a,
       const char *m, const char *o,
       const char *v);
 int archive_write_set_option(struct archive *_a,
       const char *m, const char *o,
       const char *v);
 int archive_write_set_options(struct archive *_a,
       const char *opts);
 struct archive *archive_write_disk_new(void);
 int archive_write_disk_set_skip_file(struct archive *,
    long long, long long);
 int archive_write_disk_set_options(struct archive *,
       int flags);
 int archive_write_disk_set_standard_lookup(struct archive *);
 int archive_write_disk_set_group_lookup(struct archive *,
    void * ,
    long long (*)(void *, const char *, long long),
    void (* )(void *));
 int archive_write_disk_set_user_lookup(struct archive *,
    void * ,
    long long (*)(void *, const char *, long long),
    void (* )(void *));
 long long archive_write_disk_gid(struct archive *, const char *, long long);
 long long archive_write_disk_uid(struct archive *, const char *, long long);
 struct archive *archive_read_disk_new(void);
 int archive_read_disk_set_symlink_logical(struct archive *);
 int archive_read_disk_set_symlink_physical(struct archive *);
 int archive_read_disk_set_symlink_hybrid(struct archive *);
 int archive_read_disk_entry_from_file(struct archive *,
    struct archive_entry *, int , const struct stat *);
 const char *archive_read_disk_gname(struct archive *, long long);
 const char *archive_read_disk_uname(struct archive *, long long);
 int archive_read_disk_set_standard_lookup(struct archive *);
 int archive_read_disk_set_gname_lookup(struct archive *,
    void * ,
    const char *(* )(void *, long long),
    void (* )(void *));
 int archive_read_disk_set_uname_lookup(struct archive *,
    void * ,
    const char *(* )(void *, long long),
    void (* )(void *));
 int archive_read_disk_open(struct archive *, const char *);
 int archive_read_disk_open_w(struct archive *, const wchar_t *);
 int archive_read_disk_descend(struct archive *);
 int archive_read_disk_can_descend(struct archive *);
 int archive_read_disk_current_filesystem(struct archive *);
 int archive_read_disk_current_filesystem_is_synthetic(struct archive *);
 int archive_read_disk_current_filesystem_is_remote(struct archive *);
 int archive_read_disk_set_atime_restored(struct archive *);
 int archive_read_disk_set_behavior(struct archive *,
      int flags);
 int archive_read_disk_set_matching(struct archive *,
      struct archive *_matching, void (*_excluded_func)
      (struct archive *, void *, struct archive_entry *),
      void *_client_data);
 int archive_read_disk_set_metadata_filter_callback(struct archive *,
      int (*_metadata_filter_func)(struct archive *, void *,
       struct archive_entry *), void *_client_data);
 int archive_free(struct archive *);
 int archive_filter_count(struct archive *);
 long long archive_filter_bytes(struct archive *, int);
 int archive_filter_code(struct archive *, int);
 const char * archive_filter_name(struct archive *, int);
 long long archive_position_compressed(struct archive *)
    __attribute__((deprecated));
 long long archive_position_uncompressed(struct archive *)
    __attribute__((deprecated));
 const char *archive_compression_name(struct archive *)
    __attribute__((deprecated));
 int archive_compression(struct archive *)
    __attribute__((deprecated));
 int archive_errno(struct archive *);
 const char *archive_error_string(struct archive *);
 const char *archive_format_name(struct archive *);
 int archive_format(struct archive *);
 void archive_clear_error(struct archive *);
 void archive_set_error(struct archive *, int _err,
       const char *fmt, ...) ;
 void archive_copy_error(struct archive *dest,
       struct archive *src);
 int archive_file_count(struct archive *);
 struct archive *archive_match_new(void);
 int archive_match_free(struct archive *);
 int archive_match_excluded(struct archive *,
      struct archive_entry *);
 int archive_match_path_excluded(struct archive *,
      struct archive_entry *);
 int archive_match_exclude_pattern(struct archive *, const char *);
 int archive_match_exclude_pattern_w(struct archive *,
      const wchar_t *);
 int archive_match_exclude_pattern_from_file(struct archive *,
      const char *, int _nullSeparator);
 int archive_match_exclude_pattern_from_file_w(struct archive *,
      const wchar_t *, int _nullSeparator);
 int archive_match_include_pattern(struct archive *, const char *);
 int archive_match_include_pattern_w(struct archive *,
      const wchar_t *);
 int archive_match_include_pattern_from_file(struct archive *,
      const char *, int _nullSeparator);
 int archive_match_include_pattern_from_file_w(struct archive *,
      const wchar_t *, int _nullSeparator);
 int archive_match_path_unmatched_inclusions(struct archive *);
 int archive_match_path_unmatched_inclusions_next(
      struct archive *, const char **);
 int archive_match_path_unmatched_inclusions_next_w(
      struct archive *, const wchar_t **);
 int archive_match_time_excluded(struct archive *,
      struct archive_entry *);
 int archive_match_include_time(struct archive *, int _flag,
      uint64_t _sec, long _nsec);
 int archive_match_include_date(struct archive *, int _flag,
      const char *_datestr);
 int archive_match_include_date_w(struct archive *, int _flag,
      const wchar_t *_datestr);
 int archive_match_include_file_time(struct archive *,
      int _flag, const char *_pathname);
 int archive_match_include_file_time_w(struct archive *,
      int _flag, const wchar_t *_pathname);
 int archive_match_exclude_entry(struct archive *,
      int _flag, struct archive_entry *);
 int archive_match_owner_excluded(struct archive *,
      struct archive_entry *);
 int archive_match_include_uid(struct archive *, long long);
 int archive_match_include_gid(struct archive *, long long);
 int archive_match_include_uname(struct archive *, const char *);
 int archive_match_include_uname_w(struct archive *,
      const wchar_t *);
 int archive_match_include_gname(struct archive *, const char *);
 int archive_match_include_gname_w(struct archive *,
      const wchar_t *);
 int archive_utility_string_sort(char **);

 struct archive;
struct archive_entry;
 struct archive_entry *archive_entry_clear(struct archive_entry *);
 struct archive_entry *archive_entry_clone(struct archive_entry *);
 void archive_entry_free(struct archive_entry *);
 struct archive_entry *archive_entry_new(void);
 struct archive_entry *archive_entry_new2(struct archive *);
 uint64_t archive_entry_atime(struct archive_entry *);
 long archive_entry_atime_nsec(struct archive_entry *);
 int archive_entry_atime_is_set(struct archive_entry *);
 uint64_t archive_entry_birthtime(struct archive_entry *);
 long archive_entry_birthtime_nsec(struct archive_entry *);
 int archive_entry_birthtime_is_set(struct archive_entry *);
 uint64_t archive_entry_ctime(struct archive_entry *);
 long archive_entry_ctime_nsec(struct archive_entry *);
 int archive_entry_ctime_is_set(struct archive_entry *);
 uint32_t archive_entry_dev(struct archive_entry *);
 int archive_entry_dev_is_set(struct archive_entry *);
 uint32_t archive_entry_devmajor(struct archive_entry *);
 uint32_t archive_entry_devminor(struct archive_entry *);
 unsigned short archive_entry_filetype(struct archive_entry *);
 void archive_entry_fflags(struct archive_entry *,
       unsigned long * ,
       unsigned long * );
 const char *archive_entry_fflags_text(struct archive_entry *);
 long long archive_entry_gid(struct archive_entry *);
 const char *archive_entry_gname(struct archive_entry *);
 const wchar_t *archive_entry_gname_w(struct archive_entry *);
 const char *archive_entry_hardlink(struct archive_entry *);
 const wchar_t *archive_entry_hardlink_w(struct archive_entry *);
 long long archive_entry_ino(struct archive_entry *);
 long long archive_entry_ino64(struct archive_entry *);
 int archive_entry_ino_is_set(struct archive_entry *);
 unsigned short archive_entry_mode(struct archive_entry *);
 uint64_t archive_entry_mtime(struct archive_entry *);
 long archive_entry_mtime_nsec(struct archive_entry *);
 int archive_entry_mtime_is_set(struct archive_entry *);
 unsigned int archive_entry_nlink(struct archive_entry *);
 const char *archive_entry_pathname(struct archive_entry *);
 const wchar_t *archive_entry_pathname_w(struct archive_entry *);
 unsigned short archive_entry_perm(struct archive_entry *);
 uint32_t archive_entry_rdev(struct archive_entry *);
 uint32_t archive_entry_rdevmajor(struct archive_entry *);
 uint32_t archive_entry_rdevminor(struct archive_entry *);
 const char *archive_entry_sourcepath(struct archive_entry *);
 const wchar_t *archive_entry_sourcepath_w(struct archive_entry *);
 long long archive_entry_size(struct archive_entry *);
 int archive_entry_size_is_set(struct archive_entry *);
 const char *archive_entry_strmode(struct archive_entry *);
 const char *archive_entry_symlink(struct archive_entry *);
 const wchar_t *archive_entry_symlink_w(struct archive_entry *);
 long long archive_entry_uid(struct archive_entry *);
 const char *archive_entry_uname(struct archive_entry *);
 const wchar_t *archive_entry_uname_w(struct archive_entry *);
 int archive_entry_is_data_encrypted(struct archive_entry *);
 int archive_entry_is_metadata_encrypted(struct archive_entry *);
 int archive_entry_is_encrypted(struct archive_entry *);
 void archive_entry_set_atime(struct archive_entry *, uint64_t, long);
 void archive_entry_unset_atime(struct archive_entry *);
 //void archive_entry_copy_bhfi(struct archive_entry *, BY_HANDLE_FILE_INFORMATION *);
 void archive_entry_set_birthtime(struct archive_entry *, uint64_t, long);
 void archive_entry_unset_birthtime(struct archive_entry *);
 void archive_entry_set_ctime(struct archive_entry *, uint64_t, long);
 void archive_entry_unset_ctime(struct archive_entry *);
 void archive_entry_set_dev(struct archive_entry *, uint32_t);
 void archive_entry_set_devmajor(struct archive_entry *, uint32_t);
 void archive_entry_set_devminor(struct archive_entry *, uint32_t);
 void archive_entry_set_filetype(struct archive_entry *, unsigned int);
 void archive_entry_set_fflags(struct archive_entry *,
     unsigned long , unsigned long );
 const char *archive_entry_copy_fflags_text(struct archive_entry *,
     const char *);
 const wchar_t *archive_entry_copy_fflags_text_w(struct archive_entry *,
     const wchar_t *);
 void archive_entry_set_gid(struct archive_entry *, long long);
 void archive_entry_set_gname(struct archive_entry *, const char *);
 void archive_entry_copy_gname(struct archive_entry *, const char *);
 void archive_entry_copy_gname_w(struct archive_entry *, const wchar_t *);
 int archive_entry_update_gname_utf8(struct archive_entry *, const char *);
 void archive_entry_set_hardlink(struct archive_entry *, const char *);
 void archive_entry_copy_hardlink(struct archive_entry *, const char *);
 void archive_entry_copy_hardlink_w(struct archive_entry *, const wchar_t *);
 int archive_entry_update_hardlink_utf8(struct archive_entry *, const char *);
 void archive_entry_set_ino(struct archive_entry *, long long);
 void archive_entry_set_ino64(struct archive_entry *, long long);
 void archive_entry_set_link(struct archive_entry *, const char *);
 void archive_entry_copy_link(struct archive_entry *, const char *);
 void archive_entry_copy_link_w(struct archive_entry *, const wchar_t *);
 int archive_entry_update_link_utf8(struct archive_entry *, const char *);
 void archive_entry_set_mode(struct archive_entry *, unsigned short);
 void archive_entry_set_mtime(struct archive_entry *, uint64_t, long);
 void archive_entry_unset_mtime(struct archive_entry *);
 void archive_entry_set_nlink(struct archive_entry *, unsigned int);
 void archive_entry_set_pathname(struct archive_entry *, const char *);
 void archive_entry_copy_pathname(struct archive_entry *, const char *);
 void archive_entry_copy_pathname_w(struct archive_entry *, const wchar_t *);
 int archive_entry_update_pathname_utf8(struct archive_entry *, const char *);
 void archive_entry_set_perm(struct archive_entry *, unsigned short);
 void archive_entry_set_rdev(struct archive_entry *, uint32_t);
 void archive_entry_set_rdevmajor(struct archive_entry *, uint32_t);
 void archive_entry_set_rdevminor(struct archive_entry *, uint32_t);
 void archive_entry_set_size(struct archive_entry *, long long);
 void archive_entry_unset_size(struct archive_entry *);
 void archive_entry_copy_sourcepath(struct archive_entry *, const char *);
 void archive_entry_copy_sourcepath_w(struct archive_entry *, const wchar_t *);
 void archive_entry_set_symlink(struct archive_entry *, const char *);
 void archive_entry_copy_symlink(struct archive_entry *, const char *);
 void archive_entry_copy_symlink_w(struct archive_entry *, const wchar_t *);
 int archive_entry_update_symlink_utf8(struct archive_entry *, const char *);
 void archive_entry_set_uid(struct archive_entry *, long long);
 void archive_entry_set_uname(struct archive_entry *, const char *);
 void archive_entry_copy_uname(struct archive_entry *, const char *);
 void archive_entry_copy_uname_w(struct archive_entry *, const wchar_t *);
 int archive_entry_update_uname_utf8(struct archive_entry *, const char *);
 void archive_entry_set_is_data_encrypted(struct archive_entry *, char is_encrypted);
 void archive_entry_set_is_metadata_encrypted(struct archive_entry *, char is_encrypted);
 const struct stat *archive_entry_stat(struct archive_entry *);
 void archive_entry_copy_stat(struct archive_entry *, const struct stat *);
 const void * archive_entry_mac_metadata(struct archive_entry *, size_t *);
 void archive_entry_copy_mac_metadata(struct archive_entry *, const void *, size_t);
 void archive_entry_acl_clear(struct archive_entry *);
 int archive_entry_acl_add_entry(struct archive_entry *,
     int , int , int ,
     int , const char * );
 int archive_entry_acl_add_entry_w(struct archive_entry *,
     int , int , int ,
     int , const wchar_t * );
 int archive_entry_acl_reset(struct archive_entry *, int );
 int archive_entry_acl_next(struct archive_entry *, int ,
     int * , int * , int * ,
     int * , const char ** );
 int archive_entry_acl_next_w(struct archive_entry *, int ,
     int * , int * , int * ,
     int * , const wchar_t ** );
 const wchar_t *archive_entry_acl_text_w(struct archive_entry *,
      int );
 const char *archive_entry_acl_text(struct archive_entry *,
      int );
 int archive_entry_acl_count(struct archive_entry *, int );
struct archive_acl;
 struct archive_acl *archive_entry_acl(struct archive_entry *);
 void archive_entry_xattr_clear(struct archive_entry *);
 void archive_entry_xattr_add_entry(struct archive_entry *,
     const char * , const void * ,
     size_t );
 int archive_entry_xattr_count(struct archive_entry *);
 int archive_entry_xattr_reset(struct archive_entry *);
 int archive_entry_xattr_next(struct archive_entry *,
     const char ** , const void ** , size_t *);
 void archive_entry_sparse_clear(struct archive_entry *);
 void archive_entry_sparse_add_entry(struct archive_entry *,
     long long , long long );
 int archive_entry_sparse_count(struct archive_entry *);
 int archive_entry_sparse_reset(struct archive_entry *);
 int archive_entry_sparse_next(struct archive_entry *,
     long long * , long long * );
struct archive_entry_linkresolver;
 struct archive_entry_linkresolver *archive_entry_linkresolver_new(void);
 void archive_entry_linkresolver_set_strategy(
 struct archive_entry_linkresolver *, int );
 void archive_entry_linkresolver_free(struct archive_entry_linkresolver *);
 void archive_entry_linkify(struct archive_entry_linkresolver *,
    struct archive_entry **, struct archive_entry **);
 struct archive_entry *archive_entry_partial_links(
    struct archive_entry_linkresolver *res, unsigned int *links);

]]