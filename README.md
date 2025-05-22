# pinepack .scm
Pine3D compact model format. Uses a different model format and lualzw for compression.

## Use
```lua
pinepack.pack_file(path)
```
Packs a standard Pine3D model file into the `scm` format.

```lua
pinepack.pack_model(model)
```
Packs model data loaded from a file into the `scm` format.

```lua
pinepack.unpack_file(path)
```
Unpacks a `.scm` file into standard Pine3D model data.

```lua
pinepack.unpack_model(model)
```
Unpacks `scm` model data into standard Pine3D model data.

## Example

```lua
local pinepack = require "pinepack"

-- Packs the Pine3D pineapple into the .scm format
local data = pinepack.pack_file("models/pineapple")

-- Saves the .scm data to a file
local file = fs.open("pinepack/result.scm", "w")
file.write(data)
file.close()

-- Unpacks a file with .scm data
data = pinepack.unpack_file("pinepack/result.scm")

-- Saves the model data. It is functionally identical to the Pine3D pineapple model.
file = fs.open("pinepack/result_unpacked", "w")
file.write(textutils.serialise(data))
file.close()
```
