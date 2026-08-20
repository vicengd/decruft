# Limpia node_modules

App de barra de menús para macOS que libera disco borrando carpetas `node_modules` de proyectos.

## Qué hace

- **Escanea** los directorios raíz configurados (por defecto `~/desarrollo`) buscando carpetas `node_modules`, ignorando las anidadas dentro de otras `node_modules`.
- Para cada una muestra el **proyecto**, su **tamaño** y los **días de inactividad** (modificación más reciente de los ficheros del proyecto, excluyendo `node_modules`, builds y `.git`).
- **Borrado manual**: selecciona las que quieras y pulsa "Borrar seleccionados". Borrado directo (equivalente a `rm -rf`), sin Papelera — `node_modules` se regenera con `npm install`.
- **Limpieza automática diaria** (opcional): una vez al día borra solo los `node_modules` de proyectos inactivos ≥ N días (15 por defecto, configurable). Notificación de macOS con lo liberado.
- **Modo solo mostrar (dry-run)**: activado por defecto. No borra nada; enseña qué se habría borrado. Desactívalo cuando hayas validado la lista.

## Build

```sh
make build     # compila y ensambla build/Limpia node_modules.app
make run       # build + abrir
make install   # build + copiar a /Applications + abrir (recomendado para login item)
```

Requisitos: Xcode (Swift 6), macOS 14+.

## Config

`~/Library/Application Support/LimpiaNodeModules/config.json` — directorios raíz, umbral de inactividad, flags y total liberado acumulado.
