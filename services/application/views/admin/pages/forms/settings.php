<div class="content-wrapper">
    <!-- Content Header (Page header) -->
    <!-- Main content -->
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h4>System Settings</h4>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a class="text text-info" href="<?= base_url('admin/home') ?>">Home</a>
                        </li>
                        <li class="breadcrumb-item active">Settings</li>
                    </ol>
                </div>
            </div>
        </div>
        <!-- /.container-fluid -->
    </section>
    <section class="content">
        <div class="container-fluid">
            <form class="form-horizontal form-submit-event" action="<?= base_url('admin/setting/update_system_settings') ?>" method="POST" id="system_setting_form" enctype="multipart/form-data">
                <input type="hidden" id="system_configurations" name="system_configurations" required="" value="1" aria-required="true">
                <input type="hidden" id="system_timezone_gmt" name="system_timezone_gmt" value="<?= (isset($settings['system_timezone_gmt']) && !empty($settings['system_timezone_gmt'])) ? $settings['system_timezone_gmt'] : '+05:30'; ?>" aria-required="true">
                <input type="hidden" id="system_configurations_id" name="system_configurations_id" value="13" aria-required="true">
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>General Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-4">
                                        <label for="app_name">App Name <span class='text-danger text-xs'>*</span></label>
                                        <input type="text" class="form-control" name="app_name" value="<?= (isset($settings['app_name'])) ? $settings['app_name'] : '' ?>" placeholder="Name of the App - used in whole system" />
                                    </div>
                                    <div class="form-group col-md-4">
                                        <label for="support_number">Support Number <span class='text-danger text-xs'>*</span></label>
                                        <input type="text" id="numberInput" oninput="validateNumberInput(this)" class="form-control" name="support_number" value="<?= (isset($settings['support_number'])) ? $settings['support_number'] : '' ?>" placeholder="Customer support mobile number - used in whole system" />
                                    </div>
                                    <div class="form-group col-md-4">
                                        <label for="support_email">Support Email <span class='text-danger text-xs'>*</span></label>
                                        <input type="text" class="form-control" name="support_email" value="<?= (isset($settings['support_email'])) ? $settings['support_email'] : '' ?>" placeholder="Customer support email - used in whole system" />
                                    </div>

                                    <div class="form-group col-md-4">
                                        <label for="supported_locals">Country Currency Code</label>
                                        <select name="supported_locals" class="form-control">
                                            <?php
                                            $CI = &get_instance();
                                            $CI->config->load('erestro');
                                            $supported_methods = $CI->config->item('supported_locales_list');
                                            foreach ($supported_methods as $key => $value) {
                                                $text = "$key - $value "; ?>
                                                <option value="<?= $key ?>" <?= (isset($settings['supported_locals']) && !empty($settings['supported_locals']) && $key == $settings['supported_locals']) ? "selected" : "" ?>><?= $key . ' - ' . $value ?></option>
                                            <?php  }
                                            ?>
                                        </select>
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="currency">Store Currency ( Symbol or Code - $ or USD - Anyone ) <span class='text-danger text-xs'>*</span></label>
                                        <input type="text" class="form-control" name="currency" value="<?= (isset($settings['currency'])) ? $settings['currency'] : '' ?>" placeholder="Either Symbol or Code - For Example $ or USD" />
                                    </div>

                                    <div class="form-group col-md-6">
                                        <label class="system_timezone" for="system_timezone">System Timezone <span class='text-danger text-xs'>*</span></label>
                                        <select id="system_timezone" name="system_timezone" required class="form-control col-md-12 select2">
                                            <option value=" ">--Select Timezones--</option>
                                            <?php
                                            foreach ($timezone as $t) { ?>
                                                ?>
                                                <option value="<?= $t["zone"] ?>" data-gmt="<?= $t['diff_from_GMT']; ?>" <?= (isset($settings['system_timezone']) && $settings['system_timezone'] == $t["zone"]) ? 'selected' : ''; ?>><?= $t['zone'] . ' - ' . $t['diff_from_GMT'] . ' - ' . $t['time']; ?> </option>
                                            <?php } ?>
                                        </select>
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="is_email_setting_on"> Email Notification
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="is_email_setting_on" <?= (isset($settings['is_email_setting_on']) && $settings['is_email_setting_on'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                    <!-- <div class="form-group col-md-12">
                                        <div class="row">
                                            <div class="col-md-4 form-group">
                                                <label for="logo">Logo <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='logo' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($logo)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <div class=''>
                                                                    <div class='upload-media-div'><img class="img-fluid mb-2" src="<?= BASE_URL() . $logo ?>" alt="Image Not Found"></div>
                                                                    <input type="hidden" name="logo" id='logo' value='<?= $logo ?>'>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                            <div class="col-md-4 form-group">
                                                <label for="favicon">Favicon <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='favicon' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($favicon)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <img class="img-fluid mb-2" src="<?= BASE_URL() . $favicon ?>" alt="Image Not Found">
                                                                <input type="hidden" name="favicon" id='favicon' value='<?= $favicon ?>'>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                            <div class="col-md-4 form-group">
                                                <label for="cover_image">Cover Image <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='cover_image' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($cover_image)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <img class="img-fluid mb-2" src="<?= BASE_URL() . $cover_image ?>" alt="Image Not Found">
                                                                <input type="hidden" name="cover_image" id='cover_image' value='<?= $cover_image ?>'>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                        </div>
                                    </div> -->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- admin panel setting -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Admin Panel Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-12">
                                        <div class="row">
                                            <div class="col-md-4 form-group">
                                                <label for="logo">Logo <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='logo' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($logo)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <div class=''>
                                                                    <div class='upload-media-div'><img class="img-fluid mb-2" src="<?= BASE_URL() . $logo ?>" alt="Image Not Found"></div>
                                                                    <input type="hidden" name="logo" id='logo' value='<?= $logo ?>'>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                            <div class="col-md-4 form-group">
                                                <label for="favicon">Favicon <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='favicon' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($favicon)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <img class="img-fluid mb-2" src="<?= BASE_URL() . $favicon ?>" alt="Image Not Found">
                                                                <input type="hidden" name="favicon" id='favicon' value='<?= $favicon ?>'>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                            <div class="col-md-4 form-group">
                                                <label for="cover_image">Cover Image <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='cover_image' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($cover_image)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <img class="img-fluid mb-2" src="<?= BASE_URL() . $cover_image ?>" alt="Image Not Found">
                                                                <input type="hidden" name="cover_image" id='cover_image' value='<?= $cover_image ?>'>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- end -->

                <!-- rider panel settings -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Rider Panel Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-12">
                                        <div class="row">
                                            <div class="col-md-4 form-group">
                                                <label for="rider_logo">Logo <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='rider_logo' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($rider_logo)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <div class=''>
                                                                    <div class='upload-media-div'><img class="img-fluid mb-2" src="<?= BASE_URL() . $rider_logo ?>" alt="Image Not Found"></div>
                                                                    <input type="hidden" name="rider_logo" id='rider_logo' value='<?= $rider_logo ?>'>
                                                                </div>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                            <div class="col-md-4 form-group">
                                                <label for="rider_favicon">Favicon <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='rider_favicon' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($rider_favicon)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <img class="img-fluid mb-2" src="<?= BASE_URL() . $rider_favicon ?>" alt="Image Not Found">
                                                                <input type="hidden" name="rider_favicon" id='rider_favicon' value='<?= $rider_favicon ?>'>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                            <div class="col-md-4 form-group">
                                                <label for="rider_cover_image">Cover Image <span class='text-danger text-xs'>*</span></label>
                                                <div class="col-sm-10">
                                                    <div class='col-md-3'><a class="uploadFile img btn btn-info text-white btn-sm" data-input='rider_cover_image' data-isremovable='0' data-is-multiple-uploads-allowed='0' data-toggle="modal" data-target="#media-upload-modal" value="Upload Photo"><i class='fa fa-upload'></i> Upload</a></div>
                                                    <?php
                                                    if (!empty($rider_cover_image)) {
                                                    ?>
                                                        <label class="text-danger mt-3">*Only Choose When Update is necessary</label>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded m-4 text-center grow image">
                                                                <img class="img-fluid mb-2" src="<?= BASE_URL() . $rider_cover_image ?>" alt="Image Not Found">
                                                                <input type="hidden" name="rider_cover_image" id='rider_cover_image' value='<?= $rider_cover_image ?>'>
                                                            </div>
                                                        </div>
                                                    <?php
                                                    } else { ?>
                                                        <div class="container-fluid row image-upload-section">
                                                            <div class="col-md-3 col-sm-12 shadow p-3 mb-5 bg-white rounded text-center grow image d-none">
                                                            </div>
                                                        </div>
                                                    <?php } ?>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- end -->

                <div class="row">
                    <div class="col-md-6">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Google Map Key Settings</h4>
                                <hr>
                                <div class="form-group col-md-12">
                                    <label class="text text-danger">
                                        Set Two Google Map API KEY to secure your appliation and panel <strong> Google Map </strong> Usage
                                        <ol>
                                            <li>Maps JavaScript API KEY for admin panel MAP usage.</li>
                                            <li>Google Map API KEY for Application usage.</li>
                                        </ol>
                                    </label>
                                </div>
                                <div class="form-group col-md-6">
                                    <label for="google_map_javascript_api_key"> Maps JavaScript API KEY <span class='text-danger text-xs'>*</span></label>
                                    <input type="text" class="form-control" name="google_map_javascript_api_key" value="<?= (isset($settings['google_map_javascript_api_key']) && defined('ALLOW_MODIFICATION') && ALLOW_MODIFICATION == 0) ? str_repeat("X", strlen($settings['google_map_javascript_api_key']) - 3) . substr($settings['google_map_javascript_api_key'], -3) : $settings['google_map_javascript_api_key'] ?>" placeholder="Enter your Google Map JavaScript API KEY" />
                                </div>
                                <div class="form-group col-md-6">
                                    <label for="google_map_api_key"> Google Map API KEY (For Application) <span class='text-danger text-xs'>*</span></label>
                                    <input type="text" class="form-control" name="google_map_api_key" value="<?= (isset($settings['google_map_api_key']) && defined('ALLOW_MODIFICATION') && ALLOW_MODIFICATION == 0) ? str_repeat("X", strlen($settings['google_map_api_key']) - 3) . substr($settings['google_map_api_key'], -3) : $settings['google_map_api_key'] ?>" placeholder="Enter your Google Map API KEY" />
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Delivery Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-4">
                                        <label for="is_rider_otp_setting_on"> Order Delivery OTP System
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" class="is_rider_otp_setting_on" name="is_rider_otp_setting_on" <?= (isset($settings['is_rider_otp_setting_on']) && $settings['is_rider_otp_setting_on'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Version Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-6">
                                        <label for="is_version_system_on">Version System Status </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="is_version_system_on" <?= (isset($settings['is_version_system_on']) && $settings['is_version_system_on'] == '1') ? 'Checked' : '' ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="current_version">Current Version Of Android APP <span class='text-danger text-xs'>*</span></label>
                                        <input type="text" class="form-control" name="current_version" value="<?= (isset($settings['current_version'])) ? $settings['current_version'] : '' ?>" placeholder='Current For Version For Android APP' />
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="current_version">Current Version Of IOS APP <span class='text-danger text-xs'>*</span></label>
                                        <input type="text" class="form-control" name="current_version_ios" value="<?= (isset($settings['current_version_ios'])) ? $settings['current_version_ios'] : '' ?>" placeholder='Current Version For IOS APP' />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Cart Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-6">
                                        <label for="minimum_cart_amt">Minimum Cart Amount(<?= $currency ?>) <span class='text-danger text-xs'>*</span></label>
                                        <input type="number" class="form-control" name="minimum_cart_amt" value="<?= (isset($settings['minimum_cart_amt'])) ? $settings['minimum_cart_amt'] : '' ?>" placeholder='Minimum Cart Amount' min='0' />
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="max_items_cart"> Maximum Items Allowed In Cart <span class='text-danger text-xs'>*</span></label>
                                        <input type="number" class="form-control" name="max_items_cart" value="<?= (isset($settings['max_items_cart'])) ? $settings['max_items_cart'] : '' ?>" placeholder='Maximum Items Allowed In Cart' min='0' />
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="form-group col-md-6">
                                        <label for="max_items_cart"> Low stock limit <small>(Product will be considered as low stock)</small> </label>
                                        <input type="number" class="form-control" name="low_stock_limit" value="<?= (isset($settings['low_stock_limit'])) ? $settings['low_stock_limit'] : '5' ?>" placeholder='Product low stock limit' min='1' />
                                    </div>
                                </div>

                            </div>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Default Taxation System</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-4">
                                        <label for="tax"> Tax <small>You have to add Taxation from this menu <strong>Products -> Tax <a href="<?= base_url('admin/taxes/manage-taxes') ?>" target="_BLANK"><i class="fa fa-link"></i></a></strong> </small> </label>
                                        <select name="tax" class="form-control">
                                            <?php if (empty($taxes)) { ?>
                                                <option value="0" selected> No Taxes Were Added </option>
                                            <?php } ?>
                                            <?php foreach ($taxes as $row) { ?>
                                                <option value="<?= $row['id'] ?>" <?= (isset($settings['tax']) && $settings['tax'] == $row['id']) ? 'selected' : "" ?>><?= $row['title'] . " (" . $row['percentage'] . "%)" ?></option>
                                            <?php } ?>
                                        </select>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>App & System Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-3">
                                        <label for="is_app_maintenance_mode_on"> Customer App Maintenance Mode
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="is_app_maintenance_mode_on" <?= (isset($settings['is_app_maintenance_mode_on']) && $settings['is_app_maintenance_mode_on'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                    <div class="form-group col-md-3">
                                        <label for="is_rider_app_maintenance_mode_on"> Rider App Maintenance Mode
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="is_rider_app_maintenance_mode_on" <?= (isset($settings['is_rider_app_maintenance_mode_on']) && $settings['is_rider_app_maintenance_mode_on'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                    <!-- <div class="form-group col-md-3">
                                        <label for="is_partner_app_maintenance_mode_on"> Partner App Maintenance Mode
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="is_partner_app_maintenance_mode_on" <?= (isset($settings['is_partner_app_maintenance_mode_on']) && $settings['is_partner_app_maintenance_mode_on'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div> -->
                                    <!-- <div class="form-group col-md-3">
                                        <label for="is_web_maintenance_mode_on"> Web Maintenance Mode
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="is_web_maintenance_mode_on" <?= (isset($settings['is_web_maintenance_mode_on']) && $settings['is_web_maintenance_mode_on'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div> -->
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- customer app login methods options -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>App Login Methods</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-3">
                                        <label for="otp_login"> OTP login
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="otp_login" <?= (isset($settings['otp_login']) && $settings['otp_login'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                    <div class="form-group col-md-3">
                                        <label for="google_login"> Google Login
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="google_login" <?= (isset($settings['google_login']) && $settings['google_login'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                    <!-- <div class="form-group col-md-3">
                                        <label for="facebook_login"> Facebook Login
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="facebook_login" <?= (isset($settings['facebook_login']) && $settings['facebook_login'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div> -->
                                    <div class="form-group col-md-3">
                                        <label for="apple_login"> Apple Login
                                        </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="apple_login" <?= (isset($settings['apple_login']) && $settings['apple_login'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- end -->
                <div class="row">
                    <div class="col-md-12">
                        <div class="card card-info">
                            <div class="card-body">
                                <h4>Refer & Earn Settings</h4>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-2">
                                        <label for="is_refer_earn_on"> Refer & Earn Status? </label>
                                        <div class="card-body">
                                            <input type="checkbox" name="is_refer_earn_on" <?= (isset($settings['is_refer_earn_on']) && $settings['is_refer_earn_on'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                    <div class="form-group col-md-3">
                                        <label for="min_refer_earn_order_amount"> Minimum Refer & Earn Order Amount (<?= $currency ?>) </label>
                                        <input type="text" name="min_refer_earn_order_amount" class="form-control" value="<?= (isset($settings['min_refer_earn_order_amount']) && $settings['min_refer_earn_order_amount'] != '') ? $settings['min_refer_earn_order_amount'] : ''  ?>" placeholder="Amount of order eligible for bonus" />
                                    </div>
                                    <div class="form-group col-md-2">
                                        <label for="refer_earn_method">Refer & Earn Method </label>
                                        <select name="refer_earn_method" class="form-control">
                                            <option value="">Select</option>
                                            <option value="percentage" <?= (isset($settings['refer_earn_method']) && $settings['refer_earn_method'] == "percentage") ? "selected" : "" ?>>Percentage</option>
                                            <option value="amount" <?= (isset($settings['refer_earn_method']) && $settings['refer_earn_method'] == "amount") ? "selected" : "" ?>>Amount</option>
                                        </select>
                                    </div>
                                    <div class="form-group col-md-2">
                                        <label for="refer_earn_bonus">Refer & Earn Bonus (<?= $currency ?> OR %)</label>
                                        <input type="text" class="form-control" name="refer_earn_bonus" value="<?= (isset($settings['refer_earn_bonus'])) ? $settings['refer_earn_bonus'] : '' ?>" placeholder='In amount or percentages' />
                                    </div>
                                    <div class="form-group col-md-3">
                                        <label for="max_refer_earn_amount">Maximum Refer & Earn Amount (<?= $currency ?>)</label>
                                        <input type="text" class="form-control" name="max_refer_earn_amount" value="<?= (isset($settings['max_refer_earn_amount'])) ? $settings['max_refer_earn_amount'] : '' ?>" placeholder='Maximum Refer & Earn Bonus Amount' />
                                    </div>
                                    <div class="form-group col-md-3">
                                        <label for="refer_earn_bonus_times">Number of times Bonus to be given to the customer</label>
                                        <input type="text" class="form-control" name="refer_earn_bonus_times" value="<?= (isset($settings['refer_earn_bonus_times'])) ? $settings['refer_earn_bonus_times'] : '' ?>" placeholder='No of times customer will get bonus' />
                                    </div>
                                </div>
                                <hr>
                                <div class="row">
                                    <div class="form-group col-md-8">
                                        <label for="app_name">Cron Job URL <span class='text-danger text-xs'>*</span> <small>(Set this URL at your server cron job list for "once a day")</small></label>
                                        <!-- <a class="btn btn-xs btn-info text-white" data-toggle="modal" data-target="#howItWorksModal" title="How it works">How partner will get payment?</a> -->
                                        <input type="text" class="form-control" name="app_name" value="<?= base_url('admin/cron-job/settle_payment') ?>" disabled />
                                    </div>
                                </div>
                                <div class="d-flex justify-content-center">
                                    <div class="form-group" id="error_box">
                                    </div>
                                </div>
                                <div class="form-group">
                                    <button type="reset" class="btn btn-warning">Reset</button>
                                    <button type="submit" class="btn btn-info" id="submit_btn">Update Settings</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
            <!-- /.container-fluid -->
    </section>
    <div class="modal fade" id="howItWorksModal" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-xl" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <!-- <h4 class="modal-title" id="myModalLabel">How partner will get payment?</h4> -->
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body ">
                    <ol>
                        <li>
                            Cron job must be set (For once in a day) on your server for partner to be work.
                        </li>
                        <li>
                            Cron job will run every mid night at 12:00 AM.
                        </li>
                        <li>
                            Formula for partner Payment is <b>Final Total (Excluding delivery charge) / 100 * partner commission percentage</b>
                        <li>
                            <strong> Admin </strong> can view his commission in manage partner page. And <strong> partner </strong> can view admin commission on his profile section.
                        </li>
                        </li>
                        <li>
                            For example Final total is 1000 and admin commission is 20% then 1000 / 100 X 20 = 200 so 1000 - 200 = 800 will get credited into partner's wallet
                        </li>
                        <li>
                            If Order's status is delivered then only partner will get payment in his wallet.
                        </li>
                        <li>
                            If partner payment doesn't work, make sure cron job is set properly and it is working. If you don't know how to set cron job for once in a day please take help of server support or do search for it.
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </div>
    <!-- /.content -->
</div>