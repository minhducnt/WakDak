<div class="content-wrapper">
    <!-- Content Header (Page header) -->
    <!-- Main content -->
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h4>Add Rider</h4>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a class="text text-info" href="<?= base_url('admin/home') ?>">Home</a></li>
                        <li class="breadcrumb-item active">Rider</li>
                    </ol>
                </div>
            </div>
        </div><!-- /.container-fluid -->
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-12">
                    <div class="card card-info">
                        <!-- form start -->
                        <form class="form-horizontal form-submit-event" action="<?= base_url('admin/riders/add_rider'); ?>" method="POST" id="add_product_form">
                            <?php if (isset($fetched_data[0]['id'])) { ?>
                                <input type="hidden" name="edit_rider" value="<?= $fetched_data[0]['id'] ?>">
                            <?php
                            } ?>
                            <div class="card-body">
                                <div class="form-group row">
                                    <label for="name" class="col-sm-2 col-form-label">Name <span class='text-danger text-sm'>*</span></label>
                                    <div class="col-sm-10">
                                        <input type="text" class="form-control" id="name" placeholder="Rider Name" name="name" value="<?= @$fetched_data[0]['username'] ?>">
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <label for="mobile" class="col-sm-2 col-form-label">Mobile <span class='text-danger text-sm'>*</span></label>
                                    <div class="col-sm-10">
                                        <input type="text" id="numberInput" oninput="validateNumberInput(this)" class="form-control" id="mobile" placeholder="Enter Mobile" name="mobile" value="<?= @$fetched_data[0]['mobile'] ?>" min="0">
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <label for="email" class="col-sm-2 col-form-label">Email <span class='text-danger text-sm'>*</span></label>
                                    <div class="col-sm-10">
                                        <input type="email" class="form-control" id="email" placeholder="Enter Email" name="email" value="<?= @$fetched_data[0]['email'] ?>">
                                    </div>
                                </div>
                                <?php
                                if (!isset($fetched_data[0]['id'])) {
                                ?>
                                    <div class="form-group row ">
                                        <label for="password" class="col-sm-2 col-form-label">Password <span class='text-danger text-sm'>*</span></label>
                                        <div class="col-sm-10">
                                            <input type="password" class="form-control" id="password" placeholder="Enter Passsword" name="password" value="<?= @$fetched_data[0]['password'] ?>">
                                        </div>
                                    </div>
                                    <div class="form-group row ">
                                        <label for="confirm_password" class="col-sm-2 col-form-label">Confirm Password <span class='text-danger text-sm'>*</span></label>
                                        <div class="col-sm-10">
                                            <input type="password" class="form-control" id="confirm_password" placeholder="Enter Confirm Password" name="confirm_password">
                                        </div>
                                    </div>
                                <?php
                                }
                                ?>
                                <div class="form-group row">
                                    <label for="address" class="col-sm-2 col-form-label">Address <span class='text-danger text-sm'>*</span></label>
                                    <div class="col-sm-10">
                                        <input type="text" class="form-control" id="address" placeholder="Enter Address" name="address" value="<?= @$fetched_data[0]['address'] ?>">
                                    </div>
                                </div>
                                <div class="form-group row">
                                    <label for="commission_method" class="col-sm-4 col-form-label">Commission Methods <span class='text-danger text-sm'>*</span></label>
                                    <div class="col-sm-12">
                                        <select class='form-control' name="commission_method" id="commission_method">
                                            <option value=''>Select Method</option>
                                            <option value='percentage_on_delivery_charges' <?= (isset($fetched_data[0]['commission_method']) && $fetched_data[0]['commission_method'] == 'percentage_on_delivery_charges') ? 'selected' : '' ?>>Percentage on Delivery Charges</option>
                                            <option value='fixed_commission_per_order' <?= (isset($fetched_data[0]['commission_method']) && $fetched_data[0]['commission_method'] == 'fixed_commission_per_order') ? 'selected' : '' ?>>Fixed Commission per Order</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group d-none row" id="percentage_on_delivery_charges_input">
                                    <label for="percentage">Percentage on Delivery Charges(%) <span class='text-danger text-sm'>*</span></label>
                                    <input type="number" class="form-control" name="percentage" id="percentage" value="<?= @$fetched_data[0]['commission'] ?>" placeholder="Percentage on Delivery Charges applied on perticular order" min="0">
                                </div>
                                <div class="form-group d-none" id="fixed_commission_per_order_input">
                                    <label for="commission">Fixed Commission per Order(<?= $currency ?>) <span class='text-danger text-sm'>*</span> </label>
                                    <input type="number" class="form-control" name="commission" id="commission" value="<?= @$fetched_data[0]['commission'] ?>" placeholder="Amount will be transfered to wallet of rider per order" min="0">
                                </div>

                                <?php
                                $city = (isset($fetched_data[0]['serviceable_city']) &&  $fetched_data[0]['serviceable_city'] != NULL) ?  $fetched_data[0]['serviceable_city'] : "";
                                ?>
                                <div class="form-group row">
                                    <label for="cities" class="col-sm-2 col-form-label">Serviceable City <span class='text-danger text-sm'>*</span></label>
                                    <div class="col-sm-10">
                                        <select name="serviceable_city" class="serviceable_cities search_city w-100">
                                            <option value="">Select Serviceable City</option>
                                            <?php
                                            $city_name =  fetch_details("", 'cities', 'name,id', "", "", "", "", "id", $city);
                                            foreach ($city_name as $row) {
                                            ?>
                                                <option value=<?= $row['id'] ?> <?= ($row['id'] == $city) ? 'selected' : ''; ?>> <?= $row['name'] ?></option>
                                            <?php }
                                            ?>
                                        </select>
                                    </div>
                                </div>
                                <?php if (isset($fetched_data[0]['id']) && !empty($fetched_data[0]['id'])) { ?>
                                    <div class="form-group ">
                                        <label class="col-sm-3 col-form-label">Status <span class='text-danger text-sm'>*</span></label>
                                        <div id="active" class="btn-group col-sm-8">
                                            <label class="btn btn-default" data-toggle-class="btn-default" data-toggle-passive-class="btn-default">
                                                <input type="radio" name="active" value="0" <?= (isset($fetched_data[0]['active']) && $fetched_data[0]['active'] == '0') ? 'Checked' : '' ?>> Deactive
                                            </label>
                                            <label class="btn btn-primary" data-toggle-class="btn-primary" data-toggle-passive-class="btn-default">
                                                <input type="radio" name="active" value="1" <?= (isset($fetched_data[0]['active']) && $fetched_data[0]['active'] == '1') ? 'Checked' : '' ?>> Active
                                            </label>
                                        </div>
                                    </div>
                                <?php } ?>

                                <!-- ------------------ -->


                                <div class="form-group row">
                                    <label for="profile" class="col-sm-4 col-form-label">Rider Profile</label>
                                    <div class="col-sm-10">
                                        <?php if (isset($fetched_data[0]['profile']) && !empty($fetched_data[0]['profile'])) { ?>
                                            <span class="text-danger">*Leave blank if there is no change</span>
                                        <?php } ?>
                                        <input type="file" class="form-control" name="profile" id="profile" accept="image/*" />
                                    </div>
                                </div>
                                <?php if (isset($fetched_data[0]['profile']) && !empty($fetched_data[0]['profile'])) { ?>
                                    <div class="form-group ">
                                        <div class="mx-auto product-image"><a href="<?= base_url($fetched_data[0]['profile']); ?>" data-toggle="lightbox" data-gallery="gallery_restro"><img src="<?= base_url($fetched_data[0]['profile']); ?>" class="img-fluid rounded"></a></div>
                                    </div>
                                <?php } ?>

                                <!-- ------------------ -->

                                <div class="form-group col-md-4">
                                    <h4 class="h4 col-md-12">Can Cancel Order ?</h4>
                                    <div class="form-group col-md-8 col-sm-8">
                                        <label for="rider_cancel_order"> Enable / Disable</label>
                                        <div class="card-body">
                                            <input type="checkbox" name="rider_cancel_order" <?= (isset($fetched_data[0]['rider_cancel_order']) && $fetched_data[0]['rider_cancel_order'] == '1') ? 'Checked' : ''  ?> data-bootstrap-switch data-off-color="danger" data-on-color="success">
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <button type="reset" class="btn btn-warning">Reset</button>
                                    <button type="submit" class="btn btn-info" id="submit_btn"><?= (isset($fetched_data[0]['id'])) ? 'Update Rider' : 'Add Rider' ?></button>
                                </div>
                            </div>
                            <div class="d-flex justify-content-center">
                                <div class="form-group" id="error_box">
                                    <div class="card text-white d-none mb-3">
                                    </div>
                                </div>
                            </div>
                            <!-- /.card-footer -->
                        </form>
                    </div>
                    <!--/.card-->
                </div>
                <!--/.col-md-12-->
            </div>
            <!-- /.row -->
        </div><!-- /.container-fluid -->
    </section>
    <!-- /.content -->
</div>