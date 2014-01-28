# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Author: Dell Crowbar Team
# Author: SUSE LINUX Products GmbH
#

module PacemakerBarclampHelper
  def pacemaker_role_contraints
    {
      "pacemaker-cluster-founder" => {
        "unique" => false,
        "count" => 1
      },
      "pacemaker-cluster-member" => {
        "unique" => false,
        "count" => 3
      },
      "hawk-server" => {
        "unique" => false,
        "count" => 1
      }
    }
  end

end
