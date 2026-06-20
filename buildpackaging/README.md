## 🛠️ Utilisation

### MSI dedie pour ifnude (sans EXE)

Genere un MSI per-user qui installe automatiquement le payload ifnude dans:

`%LOCALAPPDATA%\NsfwManager\engines\ifnude-main`

Le script telecharge le zip officiel GitHub puis construit le MSI:

```bash
cd buildpackaging
build_ifnude_msi.bat
```

Sortie generee:

- `buildpackaging/nsfwmanager-module-ifnude-2-0.0.3.msi`

Installation silencieuse:

```bash
msiexec /i buildpackaging\nsfwmanager-module-ifnude-2-0.0.3.msi /qn
```

