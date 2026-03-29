# Legends Roleplay v2.0.0

Gamemode de Roleplay para MTA:SA (Multi Theft Auto: San Andreas) estilo Argentina.

## Características

### Sistema de Cuentas
- Registro e inicio de sesión con contraseñas hasheadas (bcrypt)
- Creación de múltiples personajes por cuenta (máximo 3)
- Auto-guardado de datos cada 5 minutos
- Sistema de payday con salarios por facción

### Sistema de Chat
- Chat IC (In Character) con rangos de distancia
- Comandos: `/me`, `/do`, `/b`, `/ooc`, `/gritar`, `/susurrar`, `/pm`
- Chat de facción: `/f`, `/fr` (radio)

### Sistema de Vehículos
- Tienda de vehículos con sistema de compra
- Sistema de combustible optimizado (tick cada 60s)
- Comandos: `/comprarauto`, `/motor`, `/lock`, `/estacionar`

### Sistema de Casas
- Compra y venta de propiedades
- Sistema de interiores con dimensiones
- Marcadores dinámicos (verde: en venta, rojo: ocupada)

### Sistema de Trabajos
- 4 trabajos: Recolector de Basura, Camionero, Taxista, Pescador
- Sistema de rutas con checkpoints
- Pago al completar rutas

### Sistema de Facciones (v2.0.0)
5 facciones estilo Argentina RP:
- **PFA** (Policía Federal Argentina) - Seguridad pública
- **SAME** (Sistema de Atención Médica de Emergencias) - Servicios médicos
- **Mecánicos** - Reparación y asistencia vehicular
- **Gobierno** - Administración gubernamental
- **Cartel del Sur** - Organización criminal

Características de facciones:
- Chat de facción (`/f`) y radio (`/fr`)
- Sistema de servicio (`/fduty`)
- Vehículos de facción (`/fvehicle`)
- Equipamiento por rango (`/fequip`)
- Uniformes (`/funiform`)
- Invitar/Expulsar/Promover/Degradar miembros
- Sede central (HQ) por facción
- Salarios por rango

### Sistema de Administración
- 4 niveles: Moderador, Administrador, Admin Senior, Fundador
- Comandos: `/kick`, `/ban`, `/unban`, `/tp`, `/traer`, `/revive`, `/freeze`, `/anuncio`

### Optimizaciones para 4GB RAM
- Colores pre-computados (evita crear tocolor cada frame)
- Cache de datos del HUD (actualización cada 200ms en vez de cada frame)
- Límite de batch para nametags (máximo 50 jugadores renderizados)
- Distance culling para nametags (25m) y marcadores 3D
- Tick de combustible cada 60 segundos
- Cache de queries SQLite (TTL: 30s)
- Limpieza automática de vehículos de facción inactivos
- Anti-fall basado en timers (cada 2s) en vez de por frame

## Estructura del Proyecto

```
├── meta.xml              # Manifiesto del recurso MTA:SA
├── shared/
│   └── config.lua        # Configuración global
├── server/
│   ├── s_database.lua    # Base de datos SQLite con cache
│   ├── s_accounts.lua    # Sistema de cuentas y personajes
│   ├── s_spawn.lua       # Spawn y mundo
│   ├── s_chat.lua        # Sistema de chat
│   ├── s_vehicles.lua    # Sistema de vehículos
│   ├── s_houses.lua      # Sistema de casas
│   ├── s_jobs.lua        # Sistema de trabajos
│   ├── s_admin.lua       # Sistema de administración
│   └── s_factions.lua    # Sistema de facciones
├── client/
│   ├── c_main.lua        # Inicialización del cliente
│   ├── c_login.lua       # GUI de login/registro
│   ├── c_hud.lua         # HUD personalizado
│   ├── c_nametags.lua    # Nametags personalizados
│   └── c_factions.lua    # GUI de facciones
└── data/                 # Datos persistentes (SQLite)
```

## Requisitos

- MTA:SA Server 1.5.9 o superior
- 4GB RAM mínimo (optimizado)

## Instalación

1. Copiar la carpeta del recurso a `mods/deathmatch/resources/`
2. Agregar `<resource src="legends-rp" startup="1" />` al `mtaserver.conf`
3. Iniciar el servidor MTA:SA

## Licencia

GPL-3.0 - Ver archivo [LICENSE](LICENSE) para más detalles.
