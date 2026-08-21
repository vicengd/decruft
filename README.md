# Escoba 🧹

**[English](#english) · [Español](#español)**

macOS menu bar app that frees disk space by deleting regenerable folders from your dev projects — `node_modules`, `.next`, Python venvs, build outputs…

App de barra de menús para macOS que libera disco borrando carpetas regenerables de tus proyectos — `node_modules`, `.next`, venvs de Python, builds…

![Escoba](docs/screenshot.png)

---

## English

### What it does

- **Scans** your configured root folders (default `~/desarrollo`) for regenerable folders: `node_modules`, `.next`, `.nuxt`, `.output`, `.svelte-kit`, `.turbo`, `.parcel-cache`, `.vite`, `.cache`, `coverage`, `.build`, Python virtualenvs (`.venv`/`venv`/`env` containing `pyvenv.cfg`), and `dist`/`build`/`out` when they are actual build output of a JS or Android project (parent has `package.json` or Gradle files).
- Shows each folder with its **project, type, size, and days of inactivity** (latest file modification in the project, excluding regenerable folders and `.git`).
- **Manual cleanup** with per-folder selection, or **daily automatic cleanup** that only touches projects inactive for ≥ N days (15 by default, configurable), with a macOS notification of what was freed.
- **Exclusions** to protect projects you are actively working on, and a **dry-run mode** (on by default) that shows what would be deleted without touching anything.
- Deletion is direct (like `rm -rf`), no Trash: everything it deletes regenerates with `npm install` or your next build. Inside vendored trees (`vendor`, `wp-includes`, `wp-admin`, `wp-content`, `site-packages`) only `node_modules` is detected — a `dist` there is installed code, not build output.

### Install

```sh
git clone https://github.com/vicengd/escoba.git
cd escoba
make install   # builds and copies Escoba.app to /Applications, then opens it
```

Requires Xcode (Swift 6) and macOS 14+. `make build` builds without installing; `make run` builds and opens from `build/`.

Config lives in `~/Library/Application Support/Escoba/config.json`.

---

## Español

### Qué hace

- **Escanea** los directorios raíz configurados (por defecto `~/desarrollo`) buscando carpetas regenerables: `node_modules`, `.next`, `.nuxt`, `.output`, `.svelte-kit`, `.turbo`, `.parcel-cache`, `.vite`, `.cache`, `coverage`, `.build`, virtualenvs de Python (`.venv`/`venv`/`env` con `pyvenv.cfg`) y `dist`/`build`/`out` cuando son output de build de un proyecto JS o Android (padre con `package.json` o Gradle).
- Para cada carpeta muestra el **proyecto**, el **tipo**, su **tamaño** y los **días de inactividad** (modificación más reciente de los ficheros del proyecto, excluyendo carpetas regenerables y `.git`).
- **Borrado manual** con selección por carpeta, o **limpieza automática diaria** que solo toca proyectos inactivos ≥ N días (15 por defecto, configurable), con notificación de macOS de lo liberado.
- **Exclusiones** para proteger proyectos en curso, y **modo solo mostrar (dry-run)**, activado por defecto: enseña qué se habría borrado sin tocar nada.
- Borrado directo (equivalente a `rm -rf`), sin Papelera: todo lo que borra se regenera con `npm install` o el siguiente build. Dentro de árboles vendorizados (`vendor`, `wp-includes`, `wp-admin`, `wp-content`, `site-packages`) solo detecta `node_modules` — un `dist` ahí es código instalado, no build regenerable.

### Instalación

```sh
git clone https://github.com/vicengd/escoba.git
cd escoba
make install   # compila, copia Escoba.app a /Applications y la abre
```

Requisitos: Xcode (Swift 6), macOS 14+. `make build` compila sin instalar; `make run` compila y abre desde `build/`.

La configuración vive en `~/Library/Application Support/Escoba/config.json`.

---

## License / Licencia

[MIT](LICENSE)
