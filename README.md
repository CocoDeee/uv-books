# uv-books
### A QBCore FiveM Resource by CocoDeee
**Developer & Owner — Uncanny Valley RP**

**Discord For Uncanny Valley: https://discord.gg/xHhGMqSeFZ Please let me know if you have any issues or need help!**

*If you use this resource, a credit or a star on the repo is always appreciated but never required. Enjoy.*

---

## What Is This?

uv-books is an in-game book writing and reading system for QBCore servers. Players can pick up a blank book item, write their own multi-page book inside a custom UI, sign it (or publish anonymously), and then keep that finished book as a unique item in their inventory — with every word they wrote saved to it permanently.

Other players can pick up that book and read it, page by page, exactly as it was written.

There was nothing out there that did this the way I wanted it done. I was inspired by playing RedM, where books and written notes added so much to roleplay and world-building. I wanted to bring that same feeling to FiveM — something tactile, immersive, and personal. So I built it myself.

---

## What Can Players Do?

- **Write a book** — Use a blank `book` item to open the writing UI. You can write across up to 20 pages, each holding up to 800 characters.
- **Title their book** — Give the book a custom title before publishing.
- **Sign or publish anonymously** — Choose to sign the book with a name (your character name, a pen name, anything) or leave the author as Unknown.
- **Publish** — Once finished, the book is saved to your inventory as a unique item with all your writing stored inside it.
- **Read** — Use any published book to open the reader UI and flip through the pages. The title page shows the book title and author. Every page is readable just as it was written.
- **Close anytime** — Press ESC or use the close button to exit the UI at any point.

---

## How It Works (Practically)

Every `book` item in the game shares the same base item, but when a book is published it carries its own unique data — title, author, page count, and the full written content. This means two books can look identical in your inventory but contain completely different stories inside.

Blank books open the writer. Books that have already been written and published open the reader. The script handles this automatically based on what's stored in the item.

---

## Installation

### 1. Add the resource
Drop the `uv-books` folder into your server's `resources` directory.

Add the following to your `server.cfg`:
```
ensure uv-books
```

### 2. Add the item to your items.lua
In your QBCore shared items file (`qb-core/shared/items.lua`), add the following:
```lua
['book'] = {['name'] = 'book', ['label'] = 'Book', ['weight'] = 500, ['type'] = 'item', ['image'] = 'book.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'A blank book, waiting to be written in.'},
```
For Qbox/ ox_inventory:

['book'] = {
    label = 'Book',
    weight = 200,
    stack = false,
    close = true,
    consume = 0,
    server = {
        export = 'uv-books.book'
    }
},

### 3. Add the item image
Place `book.png` into your inventory images folder.

> If you are using **qb-inventory**, this is: `qb-inventory/html/images/`
> If you are using **ox_inventory**, this is: `ox_inventory/web/images/`
> If you are using **qs-inventory**, this is: `qs-inventory/html/images/`

The image I made is included in the `images` folder

### 4. Give players blank books
You can give a blank book to a player via the server console or tie it to a shop/crafting system:
```
/giveitem [playerid] book 1
```
All books will open reader view until they are written in/ published
---

## Dependencies

- [QBCore Framework](https://github.com/qbcore-framework/qb-core)
- A compatible inventory resource (qb-inventory, ox_inventory, qs-inventory, etc.)

---

## Planned Features

- 🎬 **Animated page flip** — A visual page-turn animation when switching between pages
- 🖨️ **Printing Press Script** — A companion resource featuring an NPC printing press operator who can make copies of any published book for a fee. The NPC will be fully placeable at any `vec4` coordinate of your choosing on your server
- 🗺️ More to come as Uncanny Valley RP grows

---

## Notes

- Books are **unique items** — each published book is its own instance with its own content
- The blank book item and the published book are the same `book` item — the script detects whether content exists and opens the writer or reader accordingly
- Signing a book is optional — unsigned books display as written by `Unknown`

---

## Extras

Feel free to modify, change or improve the source code, please do not remove my name, and do not sell this script, see LICENSE

## Credits

Created by **CocoDeee**
Developer & Owner of **Uncanny Valley RP**


