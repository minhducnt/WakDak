<?php

defined('BASEPATH') or exit('No direct script access allowed');
class Branch_model extends CI_Model
{

    public function __construct()
    {
        $this->load->database();
        $this->load->library(['ion_auth', 'form_validation']);
        $this->load->helper(['url', 'language', 'function_helper']);
    }

    public function add_branch($data, $working_time)
    {
        $data = escape_array($data);
        // echo "<pre>";
        // print_r($data);

        $default_branch = fetch_details(['default_branch' => 1], 'branch', "*");
        $test = empty($default_branch) ? 1 : 0;
        if (isset($data['default_mode']) && $data['default_mode'] == 'on') {

            update_details(['default_branch' => 0], ['default_branch' => 1], 'branch');
        }
        $attr_data = [
            'branch_name' => $data['branch_name'],
            'description' => $data['description'],
            'address' => $data['address'],
            'city_id' => $data['city'],
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'email' => $data['email'],
            'contact' => intval($data['contact']),
            'status' => $data['status'],
            // 'type' => $data['type'],
            'default_branch' => $test,
            // 'default_branch' => isset($data['default_mode']) && $data['default_mode'] == 'on' ? 1 : 0,
            'self_pickup' => isset($data['self_pickup']) && $data['self_pickup'] == 'on' ? 1 : 0,
            'deliver_orders' => isset($data['deliver_orders']) && $data['deliver_orders'] == 'on' ? 1 : 0
        ];

        if (isset($data['edit_branch']) && !empty($data['edit_branch'])) {
            $this->db->set($attr_data)->where('id', $data['edit_branch'])->update('branch');

            // print_r($this->db->last_query());

            if (isset($working_time) && !empty($working_time)) {

                delete_details(['branch_id' => $data['edit_branch']], 'branch_timings');
                $branch_timing = json_decode($working_time, true);

                for ($i = 0; $i < count($branch_timing); $i++) {


                    $branch_timing_data = [
                        'branch_id' => $data['edit_branch'],
                        'day' => $branch_timing[$i]['day'],
                        'opening_time' => $branch_timing[$i]['opening_time'],
                        'closing_time' => $branch_timing[$i]['closing_time'],
                        'is_open' => $branch_timing[$i]['is_open']

                    ];
                    $this->db->insert('branch_timings', $branch_timing_data);
                }
            }

            if (isset($data['branch_image'])) {
                $attr_data['image'] = $data['branch_image'];
            }


            return $data['edit_branch'];
        } else {
            $branch_timing = json_decode($working_time, true);

            if (isset($data['branch_image'])) {
                $attr_data['image'] = $data['branch_image'];
            }
            $this->db->insert('branch', $attr_data);
            $branch_id = $this->db->insert_id();
            if (empty($default_branch)) {
                save_branch($branch_id);
            }


            for ($i = 0; $i < count($branch_timing); $i++) {


                $branch_timing_data = [
                    'branch_id' => $branch_id,
                    'day' => $branch_timing[$i]['day'],
                    'opening_time' => $branch_timing[$i]['opening_time'],
                    'closing_time' => $branch_timing[$i]['closing_time'],
                    'is_open' => $branch_timing[$i]['is_open']

                ];
                $this->db->insert('branch_timings', $branch_timing_data);
            }


            return $branch_id;
        }
    }

    public function get_branch_list(
        $partner_id = NULL,
        $offset = 0,
        $limit = 10,
        $sort = 'b.id',
        $order = 'DESC'
    ) {
        $multipleWhere = '';

        if (isset($_GET['offset']))
            $offset = $_GET['offset'];
        if (isset($_GET['limit']))
            $limit = $_GET['limit'];

        if (isset($_GET['sort']))
            if ($_GET['sort'] == 't.id') {
                $sort = "b.id";
            } else {
                $sort = $_GET['sort'];
            }
        if (isset($_GET['order']))
            $order = $_GET['order'];

        if (isset($_GET['search']) and $_GET['search'] != '') {
            $search = $_GET['search'];
            $multipleWhere = ['b.branch_name' => $search];
        }

        $count_res = $this->db->select(' COUNT(b.id) as `total`');

        // if (isset($partner_id) and $partner_id != '') {
        //     $count_res->join("partner_tags rt", "t.id=rt.tag_id", "left");
        // }

        if (isset($multipleWhere) && !empty($multipleWhere)) {
            $count_res->or_like($multipleWhere);
        }
        if (isset($where) && !empty($where)) {
            $count_res->where($where);
        }

        $attr_count = $count_res->get('branch b')->result_array();

        foreach ($attr_count as $row) {
            $total = $row['total'];
        }

        $search_res = $this->db->select('b.*');
        // if (isset($partner_id) and $partner_id != '') {
        //     $search_res->join("partner_tags rt", "t.id=rt.tag_id", "left");
        // }
        if (isset($multipleWhere) && !empty($multipleWhere)) {
            $search_res->or_like($multipleWhere);
        }
        if (isset($where) && !empty($where)) {
            $search_res->where($where);
        }

        $branch_search_res = $search_res->order_by($sort, $order)->limit($limit, $offset)->group_by('b.id')->get('branch b')->result_array();
        $bulkData = array();
        $bulkData['total'] = $total;
        $rows = array();
        $tempRow = array();
        foreach ($branch_search_res as $row) {
            $row = output_escaping($row);
            if ($this->ion_auth->is_admin()) {
                // $operate = ' <a href="javascript:void(0)" class="edit_btn btn btn-success btn-xs mr-1 mb-1" title="View" data-id="' . $row['id'] . '" data-url="admin/branch/"><i class="fa fa-pen"></i></a>';
                $operate = "<a href=" . base_url('admin/branch?edit_branch=' . $row['id'] . '') . " data-id=" . $row['id'] . " class='btn btn-success btn-xs mr-1 mb-1' title='Edit' ><i class='fa fa-pen'></i></a>";
            }
            if ($row['status'] == '1') {
                $tempRow['status'] = '<a class="badge badge-success text-white" >Active</a>';
                $operate .= '<a class="btn btn-warning btn-xs update_active_status mr-1 mb-1" data-table="branch" title="Deactivate" href="javascript:void(0)" data-id="' . $row['id'] . '" data-status="' . $row['status'] . '" ><i class="fa fa-toggle-on"></i></a>';
            } else  if ($row['status'] == '0') {
                $tempRow['status'] = '<a class="badge badge-danger text-white" >Deactive</a>';
                $operate .= '<a class="btn btn-secondary mr-1 mb-1 btn-xs update_active_status" data-table="branch" href="javascript:void(0)" title="Active" data-id="' . $row['id'] . '" data-status="' . $row['status'] . '" ><i class="fa fa-toggle-off"></i></a>';
            }
            $operate .= ' <a href="javaScript:void(0)" id="delete-restro-branch" class="btn btn-danger btn-xs mr-1 mb-1" title="Delete" data-id="' . $row['id'] . '"><i class="fa fa-trash"></i></a>';

            $tempRow['id'] = $row['id'];
            $tempRow['branch_name'] = $row['branch_name'];
            $tempRow['description'] = $row['description'];
            $tempRow['longitude'] = $row['longitude'];
            $tempRow['latitude'] = $row['latitude'];
            $tempRow['address'] = $row['address'];
            $tempRow['email'] = $row['email'];
            $tempRow['contact'] = $row['contact'];
            $tempRow['operate'] = $operate;

            $rows[] = $tempRow;
        }
        $bulkData['rows'] = $rows;
        print_r(json_encode($bulkData));
    }


    function get_branch($search = NULL, $limit = NULL, $offset = NULL, $sort = 'b.id', $order = 'DESC', $id = NULL)
    {
        $multipleWhere = '';
        $where = array();
        if (!empty($search)) {
            $multipleWhere = [
                '`b.branch_name`' => $search
            ];
        }

        if (isset($id) && !empty($id) && $id != NULL) {
            $where = ['b.id' => $id];
        }

        $count_res = $this->db->select(' COUNT(b.id) as `total`');

        if (isset($multipleWhere) && !empty($multipleWhere)) {
            $count_res->group_start();
            $count_res->or_like($multipleWhere);
            $count_res->group_end();
        }

        if (isset($where) && !empty($where)) {
            $count_res->where($where);
        }

        $cat_count = $count_res->get('branch b')->result_array();
        foreach ($cat_count as $row) {
            $total = $row['total'];
        }

        $search_res = $this->db->select('*,b.id as branch_id');
        if (isset($multipleWhere) && !empty($multipleWhere)) {
            $search_res->group_start();
            $search_res->or_like($multipleWhere);
            $search_res->group_end();
        }
        if (isset($where) && !empty($where)) {
            $search_res->where($where);
        }

        $branch_search_res = $search_res->order_by($sort, $order)->limit($limit, $offset)->group_by('b.id')->get('branch b')->result_array();
        $rows = $tempRow = $bulkData = array();
        // $bulkData['error'] = (empty($branch_search_res)) ? true : false;
        // $bulkData['message'] = (empty($branch_search_res)) ? 'Branch does not exist' : 'Branch retrieved successfully';
        $bulkData['total'] = (empty($branch_search_res)) ? 0 : $total;
        if (!empty($branch_search_res)) {
            foreach ($branch_search_res as $row) {
                $row = output_escaping($row);
                $tempRow['id'] = $row['branch_id'];
                $tempRow['title'] = $row['branch_name'];
                $tempRow['description'] = $row['description'];
                $tempRow['address'] = $row['address'];
                $tempRow['city_id'] = $row['city_id'];
                $tempRow['latitude'] = $row['latitude'];
                $tempRow['longitude'] = $row['longitude'];
                $tempRow['image'] = get_image_url($row['image'], 'thumb', 'sm');
                $tempRow['date_created'] = $row['date_added'];
                $rows[] = $tempRow;
            }
            // print_R(count($branch_search_res));
            $bulkData['total'] = count($branch_search_res);
            $bulkData = $rows;
        } else {
            $bulkData['total'] = 0;
            $bulkData = [];
        }
        // echo "<pre>";
        // print_r($bulkData);
        return $bulkData;
    }

    //  ----------------------------------------------------------------------------------------------------------------------------
    // for API
    // function get_branches($search = NULL, $limit = NULL, $offset = NULL, $sort = 'b.id', $order = 'DESC', $id = NULL, $city_id = 'null', $latitude = 'nulll', $longitude = 'null')
    // {
    //     $city_data = [];

    //     if (!empty($latitude) && !empty($longitude)) {
    //         $city_data = get_cities($city_id, ["id", "name", "max_deliverable_distance"]);
    //     }

    //     $final_distance = 5;
    //     if (!empty($city_id) && $city_id != "" && $city_id != 'NULL' && !empty($latitude) && $latitude != 'NULL' && $longitude != 'NULL' && !empty($longitude)) {
    //         $max_distance = fetch_details(['id' => $city_id], "cities", "max_deliverable_distance");
    //         $final_distance = isset($max_distance[0]['max_deliverable_distance']) ? $max_distance[0]['max_deliverable_distance'] : 5;
    //     }

    //     $where_near_by = "";
    //     if (!empty($city_id) && $city_id != "" && $city_id != "null" && !empty($latitude) && $latitude != "null" && $longitude != "null" && !empty($longitude)) {
    //         $where_near_by = "((ST_Distance_Sphere(POINT(b.latitude,b.longitude), ST_GeomFromText('POINT(" . $latitude . " " . $longitude . ")') )/ 1000 <= " . $final_distance . " AND b.city_id = " . $city_id . ")";
    //         foreach ($city_data as $value) {
    //             $where_near_by .= " OR (ST_Distance_Sphere(POINT(b.latitude,b.longitude), ST_GeomFromText('POINT(" . $latitude . " " . $longitude . ")') )/ 1000 <= " . $value['max_deliverable_distance'] . " AND b.city_id = " . $value['id'] . ")";
    //         }
    //         $where_near_by .= ")";
    //     }
    //     $multipleWhere = '';
    //     $where = array();
    //     if (!empty($search)) {
    //         $multipleWhere = [
    //             '`b.branch_name`' => $search
    //         ];
    //     }

    //     if (isset($id) && !empty($id) && $id != NULL) {
    //         $where = ['b.id' => $id];
    //         // $where = ['b.status' => 1];
    //     }

    //     $count_res = $this->db->select('COUNT(b.id) as total');

    //     if (isset($multipleWhere) && !empty($multipleWhere)) {
    //         $count_res->group_start();
    //         $count_res->or_like($multipleWhere);
    //         $count_res->group_end();
    //     }

    //     if (isset($where_near_by) && !empty($where_near_by)) {
    //         $count_res->where(['b.status' => 1]);
    //         $count_res->where($where);
    //         $count_res->where($where_near_by);
    //     }

    //     $cat_count = $count_res->get('branch b')->result_array();
    //     $total = isset($cat_count[0]['total']) ? $cat_count[0]['total'] : 0;

    //     $search_res = $this->db->select('*, b.id as branch_id');
    //     if (isset($multipleWhere) && !empty($multipleWhere)) {
    //         $search_res->group_start();
    //         $search_res->or_like($multipleWhere);
    //         $search_res->group_end();
    //     }
    //     if (isset($where_near_by) && !empty($where_near_by)) {
    //         $search_res->where(['b.status' => 1]);
    //         $search_res->where($where);
    //         $search_res->where($where_near_by);
    //     }

    //     $search_res->join('cities c', 'c.id = b.city_id', 'left');

    //     $search_res->order_by($sort, $order);

    //     if ($limit != NULL) {
    //         $search_res->limit($limit, $offset);
    //     }

    //     $branch_search_res = $search_res->get('branch b')->result_array();
    //     // echo "<pre>";
    //     // print_r($branch_search_res);

    //     $rows = [];
    //     if (!empty($branch_search_res)) {
    //         foreach ($branch_search_res as $branch) {
    //             $branch['image'] = (!empty($branch['image'])) ? base_url() . $branch['image'] : '';
    //             $branch['date_created'] = date('Y-m-d H:i:s', strtotime($branch['date_added']));
    //             $rows[] = $branch;
    //         }
    //     }

    //     $bulkData['total'] = (empty($branch_search_res)) ? 0 : $total;
    //     if (!empty($branch_search_res)) {

    //         $bulkData['data'] = $rows;
    //     } else {
    //         $bulkData['data'] = [];
    //     }
    //     // print_r($bulkData);
    //     return $bulkData;
    // }

    function get_branches($search = NULL, $limit = NULL, $offset = NULL, $sort = 'b.id', $order = 'DESC', $id = NULL, $city_id = 'null', $latitude = 'null', $longitude = 'null')
    {
        $city_data = [];

        if (!empty($latitude) && !empty($longitude)) {
            $city_data = get_cities($city_id, ["id", "name", "max_deliverable_distance"]);
        }

        $final_distance = 5;
        if (!empty($city_id) && $city_id != "" && $city_id != 'NULL' && !empty($latitude) && $latitude != 'NULL' && !empty($longitude) && $longitude != 'NULL') {
            $max_distance = fetch_details(['id' => $city_id], "cities", "max_deliverable_distance");
            $final_distance = isset($max_distance[0]['max_deliverable_distance']) ? $max_distance[0]['max_deliverable_distance'] : 5;
        }

        $where_near_by = "";
        if (!empty($city_id) && $city_id != "" && $city_id != "null" && !empty($latitude) && $latitude != "null" && !empty($longitude) && $longitude != "null") {
            $where_near_by = "((ST_Distance_Sphere(POINT(b.latitude,b.longitude), ST_GeomFromText('POINT(" . $latitude . " " . $longitude . ")') )/ 1000 <= " . $final_distance . " AND b.city_id = " . $city_id . ")";
            foreach ($city_data as $value) {
                $where_near_by .= " OR (ST_Distance_Sphere(POINT(b.latitude,b.longitude), ST_GeomFromText('POINT(" . $latitude . " " . $longitude . ")') )/ 1000 <= " . $value['max_deliverable_distance'] . " AND b.city_id = " . $value['id'] . ")";
            }
            $where_near_by .= ")";
        }

        // Adjusted SQL query to order by distance and limit to 1 result
        $search_res = $this->db->select('*, b.id as branch_id,b.latitude as latitude,b.longitude as longitude');
        if (isset($multipleWhere) && !empty($multipleWhere)) {
            $search_res->group_start();
            $search_res->or_like($multipleWhere);
            $search_res->group_end();
        }
        if (isset($where_near_by) && !empty($where_near_by)) {
            $search_res->where(['b.status' => 1]);
            $search_res->where($where_near_by);

            // Order by distance and limit to 1 result
            $search_res->order_by("ST_Distance_Sphere(POINT(b.latitude, b.longitude), ST_GeomFromText('POINT($latitude $longitude)'))");
            $search_res->limit(1);
        }

        $search_res->join('cities c', 'c.id = b.city_id', 'left');

        $branch_search_res = $search_res->get('branch b')->result_array();


        $rows = [];
        if (!empty($branch_search_res)) {
            foreach ($branch_search_res as $branch) {
                $branch['image'] = (!empty($branch['image'])) ? base_url() . $branch['image'] : '';
                $branch['date_created'] = date('Y-m-d H:i:s', strtotime($branch['date_added']));
                $rows[] = $branch;
            }
        }

        $bulkData['total'] = (empty($branch_search_res)) ? 0 : 1; // Total is now 1 if a nearest branch is found
        $bulkData['data'] = $rows;

        return $bulkData;
    }
}
