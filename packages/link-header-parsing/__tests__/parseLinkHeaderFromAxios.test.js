/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import parseLinkHeader from '../parseLinkHeaderFromAxios'

describe('parseLinkHeader', () => {
  it('pulls out the links from an Axios response header', () => {
    const axiosResponse = {
      data: {},
      headers: {
        link:
          '<http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50>; rel="current",' +
          '<http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50>; rel="first",' +
          '<http://canvas.example.com/api/v1/someendpoint&page=2&per_page=50>; rel="next",' +
          '<http://canvas.example.com/api/v1/someendpoint&page=3&per_page=50>; rel="last"'
      }
    }

    // to verify it matches manually
    expect(parseLinkHeader(axiosResponse)).toEqual({
      current: 'http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50',
      first: 'http://canvas.example.com/api/v1/someendpoint&page=1&per_page=50',
      next: 'http://canvas.example.com/api/v1/someendpoint&page=2&per_page=50',
      last: 'http://canvas.example.com/api/v1/someendpoint&page=3&per_page=50'
    })

    // verifies the exact same thing but uses a snapshot
    expect(parseLinkHeader(axiosResponse)).toMatchSnapshot()
  })
})
