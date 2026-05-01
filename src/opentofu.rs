use std::{
    fs,
    time::{Duration, SystemTime},
};

use zed::LanguageServerId;
use zed_extension_api::{self as zed, Result, serde_json, settings::LspSettings};

struct OpenTofuExtension {
    cached_binary_path: Option<String>,
}

impl OpenTofuExtension {
    const TOFU_LS: &'static str = "tofu-ls";
    const VERSION_DIR_PREFIX: &'static str = "tofu-ls-";
    const RELEASE_REPOSITORY: &'static str = "opentofu/tofu-ls";

    fn executable_name(platform: zed::Os) -> &'static str {
        match platform {
            zed::Os::Mac | zed::Os::Linux => Self::TOFU_LS,
            zed::Os::Windows => "tofu-ls.exe",
        }
    }

    fn asset_name(platform: zed::Os, arch: zed::Architecture) -> String {
        format!(
            "tofu-ls_{os}_{arch}.tar.gz",
            os = match platform {
                zed::Os::Mac => "Darwin",
                zed::Os::Linux => "Linux",
                zed::Os::Windows => "Windows",
            },
            arch = match arch {
                zed::Architecture::Aarch64 => "arm64",
                zed::Architecture::X86 => "i386",
                zed::Architecture::X8664 => "x86_64",
            },
        )
    }

    fn installed_binary_path(executable_name: &str) -> Option<String> {
        let mut newest_binary: Option<(Duration, String)> = None;

        let entries = fs::read_dir(".").ok()?;
        for entry in entries.flatten() {
            let Ok(file_type) = entry.file_type() else {
                continue;
            };
            if !file_type.is_dir() {
                continue;
            }

            let Some(version_dir) = entry.file_name().to_str().map(str::to_owned) else {
                continue;
            };
            if !version_dir.starts_with(Self::VERSION_DIR_PREFIX) {
                continue;
            }

            let binary_path = format!("{version_dir}/{executable_name}");
            let Ok(metadata) = fs::metadata(&binary_path) else {
                continue;
            };
            if !metadata.is_file() {
                continue;
            }

            let modified = metadata
                .modified()
                .ok()
                .and_then(|time| time.duration_since(SystemTime::UNIX_EPOCH).ok())
                .unwrap_or_default();

            match &newest_binary {
                Some((best_modified, _)) if modified <= *best_modified => {}
                _ => newest_binary = Some((modified, binary_path)),
            }
        }

        newest_binary.map(|(_, path)| path)
    }

    fn cleanup_old_versions(current_version_dir: &str) -> Result<()> {
        let entries =
            fs::read_dir(".").map_err(|e| format!("failed to list working directory: {e}"))?;
        for entry in entries {
            let entry = entry.map_err(|e| format!("failed to read directory entry: {e}"))?;
            let Ok(file_type) = entry.file_type() else {
                continue;
            };
            if !file_type.is_dir() {
                continue;
            }

            let file_name = entry.file_name();
            let Some(dir_name) = file_name.to_str() else {
                continue;
            };

            if dir_name == current_version_dir || !dir_name.starts_with(Self::VERSION_DIR_PREFIX) {
                continue;
            }

            fs::remove_dir_all(entry.path()).ok();
        }

        Ok(())
    }

    fn language_server_binary_path(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<String> {
        if let Some(path) = &self.cached_binary_path {
            if fs::metadata(path).map_or(false, |stat| stat.is_file()) {
                return Ok(path.clone());
            }
        }

        if let Some(path) = worktree.which(Self::TOFU_LS) {
            self.cached_binary_path = Some(path.clone());
            return Ok(path);
        }

        let (platform, arch) = zed::current_platform();
        let executable_name = Self::executable_name(platform);
        let asset_name = Self::asset_name(platform, arch);
        let installed_binary_path = Self::installed_binary_path(executable_name);

        zed::set_language_server_installation_status(
            language_server_id,
            &zed::LanguageServerInstallationStatus::CheckingForUpdate,
        );
        let release = match zed::latest_github_release(
            Self::RELEASE_REPOSITORY,
            zed::GithubReleaseOptions {
                require_assets: true,
                pre_release: false,
            },
        ) {
            Ok(release) => release,
            Err(err) => {
                if let Some(path) = installed_binary_path.clone() {
                    self.cached_binary_path = Some(path.clone());
                    return Ok(path);
                }

                return Err(format!(
                    "{} is not installed and cannot be downloaded without an internet connection: {err}",
                    Self::TOFU_LS,
                ));
            }
        };

        let version_dir = format!(
            "{}{version}",
            Self::VERSION_DIR_PREFIX,
            version = release.version
        );
        let binary_path = format!("{version_dir}/{executable_name}");

        if !fs::metadata(&binary_path).map_or(false, |stat| stat.is_file()) {
            let asset = match release.assets.iter().find(|asset| asset.name == asset_name) {
                Some(asset) => asset,
                None => {
                    if let Some(path) = installed_binary_path {
                        self.cached_binary_path = Some(path.clone());
                        return Ok(path);
                    }

                    return Err(format!("no asset found matching {asset_name:?}"));
                }
            };

            zed::set_language_server_installation_status(
                language_server_id,
                &zed::LanguageServerInstallationStatus::Downloading,
            );

            zed::download_file(
                &asset.download_url,
                &version_dir,
                zed::DownloadedFileType::GzipTar,
            )
            .map_err(|e| format!("failed to download file: {e}"))?;

            zed::make_file_executable(&binary_path)?;
            Self::cleanup_old_versions(&version_dir)?;
        }

        self.cached_binary_path = Some(binary_path.clone());
        Ok(binary_path)
    }
}

impl zed::Extension for OpenTofuExtension {
    fn new() -> Self {
        Self {
            cached_binary_path: None,
        }
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        Ok(zed::Command {
            command: self.language_server_binary_path(language_server_id, worktree)?,
            args: vec!["serve".to_string()],
            env: Default::default(),
        })
    }

    fn language_server_workspace_configuration(
        &mut self,
        _language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<serde_json::Value>> {
        let settings = LspSettings::for_worktree(Self::TOFU_LS, worktree)
            .ok()
            .and_then(|lsp_settings| lsp_settings.settings.clone())
            .unwrap_or_default();
        Ok(Some(settings))
    }
}

zed::register_extension!(OpenTofuExtension);
