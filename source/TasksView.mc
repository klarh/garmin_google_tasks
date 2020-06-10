using Toybox.Communications;
using Toybox.System;
using Toybox.WatchUi;

const SortTypeId = "sort_type";
const ShowCompletedId = "show_completed";
const ShowHiddenId = "show_hidden";
const TaskQueryFields = "nextPageToken,items(id,title,parent,position,notes,status)";
const TaskUrl1 = "https://www.googleapis.com/tasks/v1/lists/";
const TaskUrl2 = "/tasks/";

function arrcmp(a, b) {
    var a_size = a.size();
    var b_size = b.size();
    var min_size = a_size < b_size? a_size: b_size;

    for(var i = 0; i < min_size; i++) {
        var ai = a[i];
        var bi = b[i];

        if(ai < bi) {
            return -1;
        }
        else if(ai > bi) {
            return 1;
        }
    }

    if(a_size < b_size) {
        return -1;
    }
    else if(a_size > b_size) {
        return 1;
    }

    return 0;
}

function merge_sorted(src, dest, i, j) {
    // p and q: current indices from src[i] and src[j]
    var p = i;
    var q = j;
    // r: current index in dest
    var r = i;

    if(j > src.size()) {
        j = src.size();
    }

    var qmax = j + (j - i);
    if(qmax > src.size()) {
        qmax = src.size();
    }

    var done = p >= j || q >= qmax;
    while(!done) {
        var left = src[p];
        var right = src[q];

        if(arrcmp(left, right) <= 0) {
            dest[r] = left;
            p += 1;
        }
        else {
            dest[r] = right;
            q += 1;
        }

        r += 1;
        done = p == j || q == qmax;
    }

    while(p < j) {
        dest[r] = src[p];
        r += 1;
        p += 1;
    }

    while(q < qmax) {
        dest[r] = src[q];
        r += 1;
        q += 1;
    }
}

// Sort an array of Number arrays
function sort(arr) {
    var N = arr.size();
    var tempspace = new [N];
    var block_size = 1;

    var src = arr;
    var dest = tempspace;

    while(block_size < N) {
        for(var i = 0; i*block_size*2 < N; i++) {
            var left = i*block_size*2;
            var right = left + block_size;
            merge_sorted(src, dest, left, right);
        }
        block_size *= 2;

        var swap = src;
        src = dest;
        dest = swap;
    }

    if(arr != src) {
        for(var i = 0; i < arr.size(); i++) {
            arr[i] = src[i];
        }
    }
}

class ListTasksRequest extends Request {
    var app;
    var loading_view;
    var list_name;
    var list_id;
    var pending_rows;
    var parent_map;
    var position_map;
    var next_page_token;
    var sort_type;
    var tasks_view;
    var show_completed;
    var show_hidden;

    function initialize(app, loading_view, list_name, list_id) {
        Request.initialize();
        self.app = app;
        self.loading_view = loading_view;
        self.list_name = list_name;
        self.list_id = list_id;
        // pending tasks to load, indexed by their sort string
        self.pending_rows = {};
        // map from id -> task's parent id
        self.parent_map = {};
        // map from id -> (local) position
        self.position_map = {};
        self.next_page_token = null;

        var sort_type_setting = Application.Properties.getValue($.SortTypeId);
        if(sort_type_setting == 1) {
            self.sort_type = :sort_user;
        }
        else {
            self.sort_type = :sort_none;
        }

        self.show_completed = Application.Properties.getValue($.ShowCompletedId);
        self.show_hidden = Application.Properties.getValue($.ShowHiddenId);

        self.tasks_view = new TasksView(self.list_name);
    }

    function request(access_token, callback) {
        var params = {
            "access_token" => access_token,
            "fields" => $.TaskQueryFields,
            "maxResults" => 100,
            "showCompleted" => self.show_completed? "True": "False",
            "showHidden" => self.show_hidden? "True": "False",
        };

        if(self.next_page_token != null) {
            params["pageToken"] = self.next_page_token;
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        var url = $.TaskUrl1 + self.list_id + $.TaskUrl2;

        Communications.makeWebRequest(
            url, params, options, callback);
    }

    function run(returnCode, data) {
        var task_items = data["items"];

        if(self.sort_type == :sort_user) {
            for(var i = 0; i < task_items.size(); i++) {
                var item = task_items[i];
                var sort_key = item["position"].toNumber();
                if(sort_key == null) {
                    sort_key = i + 1024;
                }

                var parent = item["parent"];
                var item_id = item["id"];
                if(parent != null) {
                    self.parent_map[item_id] = parent;
                }

                self.position_map[item_id] = sort_key;

                self.pending_rows[item_id] = [
                    item["title"], item["notes"],
                    "completed".equals(item["status"])];
            }
        }
        else {
            for(var i = 0; i < task_items.size(); i++) {
                var item = task_items[i];
                self.tasks_view.addItem(
                    item["title"], item["notes"], item["id"],
                    "completed".equals(item["status"]));
            }
        }

        if(data["nextPageToken"] != null) {
            self.next_page_token = data["nextPageToken"];
            return :rerun;
        }
        else {
            if(self.sort_type == :sort_user) {
                var all_ids = self.pending_rows.keys();
                var position_rows = {};
                for(var i = 0; i < all_ids.size(); i++) {
                    var id = all_ids[i];
                    var item_key = [];
                    while(id != null) {
                        item_key.add(self.position_map[id]);
                        id = self.parent_map[id];
                    }

                    var end = item_key.size() - 1;

                    for(var j = 0; j < item_key.size()/2; j++) {
                        var tmp = item_key[j];
                        item_key[j] = item_key[end];
                        item_key[end] = tmp;
                        end -= 1;
                    }

                    position_rows[item_key] = all_ids[i];
                }

                var sort_keys = position_rows.keys();
                sort(sort_keys);

                for(var i = 0; i < sort_keys.size(); i++) {
                    var item_key = sort_keys[i];
                    var item_id = position_rows[item_key];
                    var item = self.pending_rows[item_id];
                    var task_name = item[0];
                    for(var j = 1; j < item_key.size(); j++) {
                        task_name = "  " + task_name;
                    }
                    self.tasks_view.addItem(task_name, item[1], item_id, item[2]);
                }
            }

            if(self.loading_view.stillAlive() && self.loading_view.get().is_visible) {
                WatchUi.switchToView(
                    self.tasks_view, new TasksDelegate(self.app, self.list_id), WatchUi.SLIDE_LEFT);
            }
            else {
                WatchUi.pushView(
                    self.tasks_view, new TasksDelegate(self.app, self.list_id), WatchUi.SLIDE_LEFT);
            }
            return null;
        }
    }
}

class CheckTaskRequest extends Request {
    var task_data;
    var list_id;
    var task_id;

    function initialize(list_id, task_id) {
        Request.initialize();
        self.task_data = null;
        self.list_id = list_id;
        self.task_id = task_id;
    }

    function request(access_token, callback) {
        if(self.task_data == null) {
            var params = {
                "access_token" => access_token,
            };

            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            };

            var url = $.TaskUrl1 + self.list_id + $.TaskUrl2 + self.task_id;

            Communications.makeWebRequest(
                url, params, options, callback);
        }
        else {
            var bearer = "Bearer " + access_token;

            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_PUT,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => bearer,
                },
            };

            var url = $.TaskUrl1 + self.list_id + $.TaskUrl2 + self.task_id;

            Communications.makeWebRequest(
                url, self.task_data, options, callback);
        }
    }

    function run(returnCode, data) {
        if("completed".equals(data["status"])) {
            data["status"] = "needsAction";
        }
        else {
            data["status"] = "completed";
        }

        var need_to_rerun = self.task_data == null;
        self.task_data = data;

        if(need_to_rerun) {
            return :rerun;
        }
        else {
            return null;
        }
    }
}

class TasksDelegate extends WatchUi.Menu2InputDelegate {
    var app;
    var list_id;

    function initialize(app, list_id) {
        Menu2InputDelegate.initialize();
        self.app = app;
        self.list_id = list_id;
    }

    function onSelect(item) {
        self.app.get().toggleTask(self.list_id, item.getId());
    }
}

class TasksView extends WatchUi.CheckboxMenu {
    function initialize(list_name) {
        CheckboxMenu.initialize({:title => list_name});
    }

    function addItem(title, note, id, check) {
        return CheckboxMenu.addItem(
            new WatchUi.CheckboxMenuItem(
                title, note, id, check, {}));
    }
}
