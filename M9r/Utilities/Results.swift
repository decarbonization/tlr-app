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

import Foundation

func mapResults<T, U>(_ results: some Sequence<Result<T, any Error>>,
                      transform: (T) throws -> U) -> [Result<U, any Error>] {
    results.map { result in
        switch result {
        case .success(let value):
            return Result(catching: { try transform(value) })
        case .failure(let error):
            return .failure(error)
        }
    }
}

func extractResults<S, F>(_ results: some Sequence<Result<S, F>>) -> (successes: [S], failures: [F]) {
    var successes = [S]()
    var failures = [F]()
    for result in results {
        switch result {
        case .success(let success):
            successes.append(success)
        case .failure(let failure):
            failures.append(failure)
        }
    }
    return (successes, failures)
}
