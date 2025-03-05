/*
 * M9r
 * Copyright (C) 2025  MAINTAINERS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

(function preflight() {
    class Player extends EventTarget {
        constructor() {
            super()
        }
        
        async postMessage(service, message) {
            const reply = await window.webkit.messageHandlers[service].postMessage(JSON.stringify(message));
            return JSON.parse(reply);
        }
        
        /** @private */
        _dispatchPlayerEvent(detail) {
            this.dispatchEvent(new CustomEvent("playerevent", { detail }));
        }
        
        /** @private */
        _dispatchLibraryEvent(detail) {
            this.dispatchEvent(new CustomEvent("libraryevent", { detail }));
        }
    }
    Object.defineProperty(window, "player", {
        value: new Player(),
        enumerable: false,
        writable: false,
    });
})();
