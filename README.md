# Escoba

App de barra de menús para macOS que libera disco borrando artefactos regenerables de proyectos de desarrollo (`node_modules`, `.next`, venvs, builds…). Antes se llamaba "Limpia node_modules".

## Qué hace

- **Escanea** los directorios raíz configurados (por defecto `~/desarrollo`) buscando artefactos regenerables: `node_modules`, `.next`, `.nuxt`, `.output`, `.svelte-kit`, `.turbo`, `.parcel-cache`, `.vite`, `.cache`, `coverage`, `.build`, virtualenvs de Python (`.venv`/`venv`/`env` con `pyvenv.cfg`) y `dist`/`build`/`out` cuando son output de build de un proyecto JS o Android (padre con `package.json` o Gradle). Dentro de árboles vendorizados (`vendor`, `wp-includes`, `wp-admin`, `wp-content`, `site-packages`) solo detecta `node_modules` — un `dist` ahí es código instalado, no build.
- Para cada artefacto muestra el **proyecto**, el **tipo**, su **tamaño** y los **días de inactividad** (modificación más reciente de los ficheros del proyecto, excluyendo artefactos y `.git`).
- **Borrado manual**: selecciona las que quieras y pulsa "Borrar seleccionados". Borrado directo (equivalente a `rm -rf`), sin Papelera — `node_modules` se regenera con `npm install`.
- **Limpieza automática diaria** (opcional): una vez al día borra solo los artefactos de proyectos inactivos ≥ N días (15 por defecto, configurable). Notificación de macOS con lo liberado.
- **Exclusiones**: proyectos en curso que no quieres regenerar cada día. Botón ⃠ en cada fila o "Excluir…" con selector de carpeta; el escáner se salta esos árboles enteros (también en la limpieza automática).
- **Modo solo mostrar (dry-run)**: activado por defecto. No borra nada; enseña qué se habría borrado. Desactívalo cuando hayas validado la lista.

## Build

```sh
make build     # compila y ensambla build/Escoba.app
make run       # build + abrir
make install   # build + copiar a /Applications + abrir (recomendado para login item)
```

Requisitos: Xcode (Swift 6), macOS 14+.

## Config

`~/Library/Application Support/Escoba/config.json` (migrado automáticamente desde LimpiaNodeModules) — directorios raíz, umbral de inactividad, flags y total liberado acumulado.
