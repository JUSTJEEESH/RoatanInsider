# Files waiting to go into the `app-data` bucket

Anything in this folder is ready to upload as-is to Supabase Storage →
project `vbxmmslzanixvqswtnnv` → bucket `app-data`. Overwrite the existing
object with the same name, then bump the matching version in `manifest.json`
so devices actually pick it up — the app only re-fetches a file when the
manifest reports a version higher than the one it has cached.

## categories.json

Six display names shortened so they stop truncating in the Browse grid:

| id            | was                 | now        |
|---------------|---------------------|------------|
| `photography` | Photography         | Photos     |
| `health`      | Health & Medical    | Health     |
| `fitness`     | Fitness & Gym       | Fitness    |
| `marina`      | Marina & Boating    | Boating    |
| `events`      | Events & Weddings   | Weddings   |
| `family`      | Kids & Family       | Family     |

`Events & Weddings` became `Weddings` specifically because "Events" already
means the live-music schedule everywhere else in the app.

`public.categories` in Postgres has already been updated to match — this file
is a straight render of that table (`indent=2`, no trailing newline, which is
byte-for-byte how the copy currently in the bucket was produced). Nothing
changes on anyone's phone until the bucket copy is replaced and the manifest
bumped.

The bundled copy at `RoatanInsider/Data/categories.json` is now identical to
this file. It used to carry a different ordering from the table, so a first
launch showed the categories in one order and every launch after the first
refresh showed another.

Ordering and icons are untouched.
