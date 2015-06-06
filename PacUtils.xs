#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <pacutils.h>

#define _STORE_BOOL(hash, key, val) hv_store(hash, key, strlen(key), newSViv(val), 0);

#define _STORE_STR(hash, key, val) do { \
    SV* sv = val ? newSVpv(val, strlen(val)) : newSV(0); \
    hv_store(hash, key, strlen(key), sv, 0); \
} while(0)

#define _STORE_STRLIST(hash, key, l) do { \
    alpm_list_t *i = l; \
    AV *pl = newAV(); \
    while(i) { \
        av_push(pl, newSVpv(i->data, strlen(i->data))); \
        i = i->next; \
    } \
    hv_store(hash, key, strlen(key), newRV_noinc((SV*) pl), 0); \
} while(0)

#define _STORE_SIGLEVEL(hash, key, l) do { \
    HV *slpkg = gv_stashpv("PacUtils::Config::SigLevel", GV_ADD); \
    SV *sl = sv_bless(newRV_noinc(newSViv(l)), slpkg); \
    hv_store(hash, key, strlen(key), sl, 0); \
} while(0)

#define _STORE_USAGE(hash, key, l) do { \
    HV *slpkg = gv_stashpv("PacUtils::Config::Usage", GV_ADD); \
    SV *sl = sv_bless(newRV_noinc(newSViv(l)), slpkg); \
    hv_store(hash, key, strlen(key), sl, 0); \
} while(0)

#define _STORE_CLEANMETHOD(hash, key, l) do { \
    HV *slpkg = gv_stashpv("PacUtils::Config::CleanMethod", GV_ADD); \
    SV *sl = sv_bless(newRV_noinc(newSViv(l)), slpkg); \
    hv_store(hash, key, strlen(key), sl, 0); \
} while(0)

#define _STORE_REPOLIST(hash, repos) do { \
    AV *repo_list = newAV(); \
    alpm_list_t *i = repos; \
    while(i) { \
        pu_repo_t *r = i->data; \
        HV *repo_hash = newHV(); \
        _STORE_STR(repo_hash, "name", r->name); \
        _STORE_STRLIST(repo_hash, "server", r->servers); \
        _STORE_SIGLEVEL(repo_hash, "sigLevel", r->siglevel); \
        _STORE_USAGE(repo_hash, "usage", r->usage); \
        av_push(repo_list, newRV_noinc((SV*) repo_hash)); \
        i = i->next; \
    } \
    hv_store(hash, "repository", strlen("repository"), newRV_noinc((SV*)repo_list), 0); \
} while(0)

MODULE = PacUtils      PACKAGE = PacUtils      PREFIX = pu_

const char *
pu_version(...)

MODULE = PacUtils      PACKAGE = PacUtils::Config

SV *
load(const char *file)
    CODE:
          pu_config_t *config = pu_config_new();
          pu_config_reader_t *reader = pu_config_reader_new(config, file);
          alpm_list_t *i;
          HV *hash;

          if(config == NULL || reader == NULL) {
            pu_config_free(config);
            pu_config_reader_free(reader);
            croak("reading '%s' failed (%s)", file, strerror(errno));
          }

          while(pu_config_reader_next(reader) != -1) {
            switch(reader->status) {
              case PU_CONFIG_READER_STATUS_INVALID_VALUE:
                warn("config %s line %d: invalid value '%s' for '%s'",
                    reader->file, reader->line, reader->value, reader->key);
                break;
              case PU_CONFIG_READER_STATUS_UNKNOWN_OPTION:
                warn("config %s line %d: unknown option '%s'",
                    reader->file, reader->line, reader->key);
                break;
              case PU_CONFIG_READER_STATUS_OK:
                /* todo debugging */
                break;
              case PU_CONFIG_READER_STATUS_ERROR:
                /* should never get here, hard errors return -1 */
                break;
            }
          }
          if(reader->error) {
            char *reason = reader->eof ? "invalid config" : strerror(errno);
            pu_config_reader_free(reader);
            pu_config_free(config);
            croak("reading '%s' failed (%s)", file, reason);
          }
          pu_config_reader_free(reader);

          if(pu_config_resolve(config) != 0) {
            croak("resolving config values failed (%s)", strerror(errno));
          }

          hash = newHV();

          _STORE_STR(hash, "root", config->rootdir);
          _STORE_STR(hash, "dbpath", config->dbpath);
          _STORE_STR(hash, "gpgdir", config->gpgdir);
          _STORE_STR(hash, "logfile", config->logfile);
          _STORE_STR(hash, "architecture", config->architecture);
          _STORE_STR(hash, "xfercommand", config->xfercommand);

          _STORE_BOOL(hash, "checkspace", config->checkspace);
          _STORE_BOOL(hash, "color", config->color);
          _STORE_BOOL(hash, "ilovecandy", config->ilovecandy);
          _STORE_BOOL(hash, "totaldownload", config->totaldownload);
          _STORE_BOOL(hash, "usesyslog", config->usesyslog);
          _STORE_BOOL(hash, "verbosepkglists", config->verbosepkglists);

          _STORE_STRLIST(hash, "cachedir", config->cachedirs);
          _STORE_STRLIST(hash, "holdpkg", config->holdpkgs);
          _STORE_STRLIST(hash, "ignorepkg", config->ignorepkgs);
          _STORE_STRLIST(hash, "ignoregroup", config->ignoregroups);
          _STORE_STRLIST(hash, "noextract", config->noextract);
          _STORE_STRLIST(hash, "noupgrade", config->noupgrade);

          _STORE_SIGLEVEL(hash, "siglevel", config->siglevel);
          _STORE_SIGLEVEL(hash, "remotefilesigLevel", config->remotefilesiglevel);
          _STORE_SIGLEVEL(hash, "localfilesigLevel", config->localfilesiglevel);

          _STORE_CLEANMETHOD(hash, "cleanmethod", config->cleanmethod);

          _STORE_REPOLIST(hash, config->repos);

          pu_config_free(config);

          RETVAL = sv_bless(newRV_noinc((SV*) hash),
              gv_stashpv("PacUtils::Config", GV_ADD));
    OUTPUT: RETVAL
