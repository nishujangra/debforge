# debforge - Build .deb packages the easy way ⚡

**debforge** is a simple, user-friendly tool to create `.deb` packages from binaries.
It wraps `dpkg-deb` with sane defaults, clean flags, and colored logging — making Debian packaging easier than ever.

> **Note**: This project was created for fun and personal use to simplify the process of creating `.deb` packages. Feel free to use it, but it's provided as-is without any guarantees.

---

## 🚀 Features

* Build `.deb` packages with **one command**
* Named flags (`-name`, `-version`, `-arch`, `-bin`, `-config`)
* Auto-generates Debian folder structure (`usr/local/bin`, `etc/`, `var/log/`)
* Includes optional config file support
* Input validation and error handling
* Verbose mode for debugging
* Configurable maintainer information
* Colored logging and progress indicators
* Produces ready-to-install `.deb` files
* Complete man page documentation

---

## 📦 Installation

### Option 1: Install .deb Package (Recommended)

Download the latest release and install:

```sh
# Download the .deb package from releases
wget https://github.com/nishujangra/debforge/releases/latest/download/debforge_1.0.0.deb

# Install the package
sudo dpkg -i debforge_1.0.0.deb

# Install dependencies if needed
sudo apt-get install -f
```

### Option 2: Build from Source

```sh
git clone https://github.com/nishujangra/debforge.git
cd debforge
chmod +x build-debforge.sh
./build-debforge.sh
sudo dpkg -i debforge_1.0.0.deb
```

### Verify Installation

After installation, verify debforge is working:

```sh
debforge --help
man debforge
```

---

## 🔧 Usage

```sh
debforge -name myapp -version 1.0.0 -arch amd64 -bin ./myapp -config ./config.yaml
```

**New features:**
- `-verbose` - Enable detailed output and package verification
- `-maintainer` - Set maintainer email (or use `DEBFORGE_MAINTAINER` env var)
- `-no-cleanup` - Keep build directory for debugging
- `-h, --help` - Show detailed help

This produces:

```sh
myapp_1.0.0_amd64.deb
```

Then install it:

```sh
sudo dpkg -i myapp_1.0.0_amd64.deb
```

---

## 📝 Example

For a binary `balancerx`:

```sh
debforge -name balancerx -version 1.0.0 -arch amd64 -bin ./balancerx -config ./config.yaml
```

Output:

```
balancerx_1.0.0_amd64.deb
```

---

## 📜 License

MIT License.