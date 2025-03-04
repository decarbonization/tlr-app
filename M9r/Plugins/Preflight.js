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
    const __m9r__ = {
        onPlayerEvent(data) {
            console.error("Unhandled player event, did you forget to load the SDK?", data);
        },
        onLibraryEvent(data) {
            console.error("Unhandled library event, did you forget to load the SDK?", data);
        },
    };
    Object.defineProperty(window, "__m9r__", {
        value: __m9r__,
        enumerable: false,
        writable: false,
    });
})();
