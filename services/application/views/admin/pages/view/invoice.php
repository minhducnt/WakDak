<div class="content-wrapper">
    <!-- Content Header (Page header) -->
    <!-- Main content -->
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1>Invoice</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item"><a class="text text-info" href="<?= base_url('admin/home'); ?>">Home</a>
                        </li>
                        <li class="breadcrumb-item active">Invoice</li>
                    </ol>
                </div>
            </div>
        </div>
        <!-- /.container-fluid -->
    </section>
    <?php

    $branch = array_values(array_unique(array_column($order_detls, "branch_id")));

    ?>
    <section class="content">
        <div class="container-fluid">
            <div class="row">
                <div class="col-md-12">
                    <div id="invoice">
                        <div class="card card-info" id="section-to-print">
                            <div class="row m-3">
                                <div class="col-md-12 d-flex justify-content-between">
                                    <h2 class="text-left">
                                        <img src="<?= base_url()  . get_settings('logo') ?>" class="d-block" style="max-width: 250px;max-height: 100px;">
                                    </h2>
                                    <h2 class="text-right">
                                        Mo. <?= $settings['support_number'] ?>
                                    </h2>
                                </div>
                                <!-- /.col -->
                            </div>
                            <!-- info row -->
                            <div class="row m-3 d-flex justify-content-between">
                                <div class="col-sm-4 invoice-col">From <address>
                                        <strong><?= $settings['app_name'] ?></strong><br>
                                        Email: <?= $settings['support_email'] ?><br>
                                        Customer Care : <?= $settings['support_number'] ?><br>
                                        <b>Order No : </b>#
                                        <?= $order_detls[0]['id'] ?>
                                        <br> <b>Date: </b>
                                        <?= date("d-m-Y, g:i A - D", strtotime($order_detls[0]['date_added'])) ?>
                                        <br>
                                        <?php if (isset($settings['tax_name']) && !empty($settings['tax_name'])) { ?>
                                            <b><?= $settings['tax_name'] ?></b> : <?= $settings['tax_number'] ?><br>
                                        <?php } ?>
                                    </address>
                                </div>
                                <!-- /.col -->
                                <div class="col-sm-4 invoice-col mb-0">Delivery Address<address>
                                        <strong><?= ($order_detls[0]['user_name'] != "") ? $order_detls[0]['user_name'] : $order_detls[0]['uname'] ?></strong><br>
                                        <?= $order_detls[0]['address'] ?><br>
                                        <strong><?= (defined('ALLOW_MODIFICATION') && ALLOW_MODIFICATION == 0) ? str_repeat("X", strlen($order_detls[0]['mobile']) - 3) . substr($order_detls[0]['mobile'], -3) : $order_detls[0]['mobile']; ?></strong><br>
                                        <strong><?= (defined('ALLOW_MODIFICATION') && ALLOW_MODIFICATION == 0) ? str_repeat("X", strlen($order_detls[0]['email']) - 3) . substr($order_detls[0]['email'], -3) : $order_detls[0]['email']; ?></strong><br>
                                    </address>
                                </div>
                                <!-- /.col -->
                            </div>
                            <!-- /.row -->
                            <!-- Table row -->
                            <!-- seller container -->
                            <?php for ($i = 0; $i < count($branch); $i++) {
                                $s_user_data = fetch_details(['id' => $partners[$i]], 'users', 'email,mobile,address,country_code,username');
                                $branch_data = fetch_details(['id' => $branch[$i]], 'branch', '*');
                                // echo "<pre>";
                                // print_r($branch_data);
                            ?>
                                <div class="container-fluid bg-light mb-0">
                                    <div class="row mx-3 mb-0">
                                        <div class="col-md-4">
                                            <p>Branch Details</p>
                                            <p><strong><?= output_escaping($branch_data[0]['branch_name']); ?></strong></p>
                                            <p>Email: <?= $branch_data[0]['email']; ?></p>
                                            <!-- <p>Owner Name: <strong><?= $s_user_data[0]['username']; ?></strong></p> -->
                                            <p> Customer Care : <?= $branch_data[0]['contact']; ?></p>
                                        </div>
                                        <div class="col-md-3">
                                            <strong>
                                                <p><?= $partner_data[0]['tax_name']; ?> : <?= $partner_data[0]['tax_number']; ?></p>
                                            </strong>
                                            <?php if (isset($order_detls[0]['is_self_pick_up']) && empty($order_detls[0]['is_self_pick_up'])) { ?>
                                                <p>Delivery By : <?= $items[$i]['rider']; ?></p>
                                                <p>Delivery Tip (<?= (isset($order_detls[0]['delivery_tip']) && !empty($order_detls[0]['delivery_tip'])) ? $settings['currency'] . $order_detls[0]['delivery_tip'] : "0"; ?>)</p>
                                            <?php } else { ?>
                                                <p class="text text-primary">Self Pickup</p>
                                            <?php } ?>
                                            <?php if (isset($partner_data[0]['pan_number']) && !empty($partner_data[0]['pan_number'])) { ?>
                                                <p>Pan Number : <?= $partner_data[0]['pan_number']; ?></p>
                                            <?php } ?>
                                        </div>
                                    </div>
                                    <div class="row m-3">
                                        <b>Product Details:</b>
                                    </div>
                                    <?php
                                    if ($branch[$i] == $items[$i]['branch_id']) { ?>
                                        <div class="row m-3">
                                            <div class="col-xs-12 table-responsive">
                                                <table class="table borderless text-center text-sm">
                                                    <thead class="">
                                                        <tr>
                                                            <th>Sr No.</th>
                                                            <th>Product Code</th>
                                                            <th>Name</th>
                                                            <th>Price</th>
                                                            <th class="d-none">Tax (%)</th>
                                                            <th class="d-none">Tax Amount (₹)</th>
                                                            <th>Qty</th>
                                                            <th>SubTotal (<?= $settings['currency'] ?>)</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <?php $j = 1;
                                                        $settings = get_settings('system_settings', true);
                                                        $tax = fetch_details(['id' => $settings['tax']], 'taxes', 'percentage');
                                                        $tax = ($tax[0]['percentage']);
                                                        $total = $quantity = $total_tax = $tax_percent = $total_discount = $final_sub_total = 0;

                                                        foreach ($items as $row) {
                                                            $total += floatval($row['price'] + $tax_amount) * floatval($row['quantity']);
                                                            if ($partners[$i] == $row['partner_id']) {
                                                                $product_variants = get_variants_values_by_id($row['product_variant_id']);
                                                                $product_variants = isset($product_variants[0]['variant_values']) && !empty($product_variants[0]['variant_values']) ? "(" . str_replace(',', ' | ', $product_variants[0]['variant_values']) . ")" : '';
                                                                $quantity += floatval($row['quantity']);
                                                                $sub_total = floatval($row['price']) * $row['quantity'];
                                                                $final_sub_total += $sub_total;
                                                        ?>
                                                                <tr>
                                                                    <td><?= $j ?><br></td>
                                                                    <td><?= $row['product_variant_id'] ?><br></td>
                                                                    <td class="w-25"><?= $row['pname'] . " " . $product_variants ?><br></td>
                                                                    <td><?= $settings['currency'] . ' ' . $row['price']; ?><br></td>
                                                                    <td class="d-none"><?= ($row['tax_percent']) ? $row['tax_percent'] : '0' ?><br></td>
                                                                    <td class="d-none"><?= $tax_amount ?><br></td>
                                                                    <td><?= $row['quantity'] ?><br></td>
                                                                    <td><?= $settings['currency'] . ' ' . $sub_total; ?><br></td>
                                                                    <td class="d-none"><?= $row['active_status'] ?><br></td>
                                                                </tr>
                                                        <?php $j++;
                                                            }
                                                        }
                                                        ?>
                                                    </tbody>
                                                    <tbody>
                                                        <tr>
                                                            <th></th>
                                                            <th></th>
                                                            <th></th>
                                                            <th>Total</th>
                                                            <th> <?= $quantity ?>
                                                                <br>
                                                            </th>
                                                            <th> <?= $settings['currency'] . ' ' . $final_sub_total; ?><br></th>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                            <!-- /.col -->
                                        </div>
                                    <?php
                                        // echo "<pre>";
                                        // print_r($order_detls);
                                    } ?>
                                </div>
                                <hr>
                            <?php }
                            // print_r($is_add_ons);
                            if (isset($is_add_ons) && in_array(true, $is_add_ons)) { ?>
                                <div class="row m-3">
                                    <p>Add Ons Details:</p>
                                </div>
                                <div class="row m-3 text-right">
                                    <!-- accepted payments column -->
                                    <div class="col-md-12">
                                        <div class="table-responsive">
                                            <table class="table table-striped text-center table-hover">
                                                <thead>
                                                    <tr>
                                                        <th scope="col">Id</th>
                                                        <th scope="col">Product Name</th>
                                                        <th scope="col">Add On</th>
                                                        <th scope="col">Quantity</th>
                                                        <th scope="col">Price</th>
                                                        <th scope="col">Total</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <?php
                                                    $final_price_add_ons = 0;
                                                    $i = 1;
                                                    foreach ($items as $row) {
                                                        if (isset($row['add_ons']) && !empty($row['add_ons']) && $row['add_ons'] != "" && $row['add_ons'] != "[]") {
                                                            $add_ons = json_decode($row['add_ons'], true);
                                                            foreach ($add_ons as $row1) {
                                                                $final_price_add_ons += intval($row1['qty']) * intval($row1['price']);
                                                    ?>
                                                                <tr>
                                                                    <th><?= $i ?></th>
                                                                    <td><?= $row['pname'] ?></td>
                                                                    <td><?= $row1['title'] ?></td>
                                                                    <td><?= $row1['qty'] ?></td>
                                                                    <td><?= intval($row1['price']) ?></td>
                                                                    <td><?= intval($row1['qty']) * intval($row1['price']) ?></td>
                                                                </tr>
                                                    <?php
                                                                $i++;
                                                            }
                                                        }
                                                    } ?>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                    <!-- /.col -->
                                </div>
                            <?php }
                            ?>
                            <!-- seller container finished -->
                            <div class="row m-3">
                                <p><b>Payment Method : </b> <?= $order_detls[0]['payment_method'] ?></p>
                            </div>
                            <!-- /.row -->
                            <div class="row m-2 text-right">
                                <!-- accepted payments column -->
                                <div class="col-md-9 offset-md-2">
                                    <!--<p class="lead">Payment Date: </p>-->
                                    <div class="table-responsive">
                                        <table class="table table-borderless">
                                            <tbody>
                                                <?php
                                                $settings = get_settings('system_settings', true);
                                                $tax = fetch_details(['id' => $settings['tax']], 'taxes', 'percentage,title');
                                                $tax_per = ($tax[0]['percentage']);
                                                $tax_name = ($tax[0]['title']);
                                                // $total_price = number_format($order_detls[0]['order_total'], 2);
                                                $tax_amount = intval($order_detls[0]['order_total']) * ($tax_per / 100);
                                                // print_r($tax_amount);
                                                ?>
                                                <tr>
                                                    <th></th>
                                                </tr>
                                                <tr class="">
                                                    <th>Tax <?= $tax_name ?> (<?= $tax_per ?>%)</th>
                                                    <td>+
                                                        <?php
                                                        echo $settings['currency'] . ' ' . number_format($tax_amount, 2); ?>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>Total Order Price(including tax charges) (
                                                        <?= $settings['currency'] ?>)</th>
                                                    <td>+
                                                        <?= number_format($order_detls[0]['order_total'], 2); ?>
                                                    </td>
                                                </tr>
                                                <?php
                                                if (isset($promo_code[0]['promo_code'])) { ?>
                                                    <tr>
                                                        <th>Promo Discount (
                                                            <?= floatval($promo_code[0]['discount']); ?>
                                                            <?= ($promo_code[0]['discount_type'] == 'percentage') ? '%' : $settings['currency']; ?> )
                                                        </th>
                                                        <td>-
                                                            <?php
                                                            echo $order_detls[0]['promo_discount'];
                                                            $total = $total - $order_detls[0]['promo_discount'];
                                                            ?>
                                                        </td>
                                                    </tr>
                                                <?php } ?>
                                                <?php if (isset($order_detls[0]['is_self_pick_up']) && empty($order_detls[0]['is_self_pick_up'])) { ?>

                                                    <tr>
                                                        <th>Delivery Charge (
                                                            <?= $settings['currency'] ?>)</th>
                                                        <td>+
                                                            <?php $total += $order_detls[0]['delivery_charge'];
                                                            echo number_format($order_detls[0]['delivery_charge'], 2); ?>
                                                        </td>
                                                    </tr>
                                                <?php } ?>
                                                <tr>
                                                    <th>Delivery Tip</th>
                                                    <td>+
                                                        <?= (isset($order_detls[0]['delivery_tip']) && !empty($order_detls[0]['delivery_tip'])) ? $settings['currency'] . $order_detls[0]['delivery_tip'] : "0"; ?>

                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>Wallet Used (
                                                        <?= $settings['currency'] ?>)</th>
                                                    <td><?php $total -= $order_detls[0]['wallet_balance'];
                                                        echo  '- ' . number_format($order_detls[0]['wallet_balance'], 2); ?> </td>
                                                </tr>
                                                <?php
                                                if (isset($order_detls[0]['discount']) && $order_detls[0]['discount'] > 0 && $order_detls[0]['discount'] != NULL) { ?>
                                                    <tr>
                                                        <th>Special Discount
                                                            <?= $settings['currency'] ?>(<?= $order_detls[0]['discount'] ?> %)</th>
                                                        <td>-
                                                            <?php echo $special_discount = round($total * $order_detls[0]['discount'] / 100, 2);
                                                            $total = floatval($total - $special_discount);
                                                            ?>
                                                        </td>
                                                    </tr>
                                                <?php
                                                }
                                                ?>
                                                <tr class="d-none">
                                                    <th>Total Payable (
                                                        <?= $settings['currency'] ?>)</th>
                                                    <td>
                                                        <?= $settings['currency'] . '  ' . $total ?>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <th>Grand Total (
                                                        <?= $settings['currency'] ?>)</th>
                                                    <td>
                                                        <?= $settings['currency'] . '  ' . number_format($order_detls[0]['total_payable'], 2) ?>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                                <!-- /.col -->
                            </div>
                        </div>
                    </div>
                    <!-- /.row -->
                    <div class="row m-3" id="section-not-to-print">
                        <div class="col-xs-12">
                            <button type='button' value='Print this page' onclick='{window.print()};' class="btn btn-default"><i class="fa fa-print"></i> Print</button>
                        </div>

                        <div class="col-md-6">
                            <a type="button" class="btn btn-default" href="<?= base_url('admin/invoice/thermal_invoice?edit_id=' . $items[0]['order_id']) ?>"><i class="fa fa-print"></i> Thermal Print</a>
                        </div>
                    </div>
                    <!-- thermal invoice section start -->
                    <!--  -->
                    <!-- thermal invoice section end -->

                    <!-- this row will not appear when printing -->

                    <!-- </div> -->
                    <!--/.card-->
                </div>
                <!--/.col-md-12-->
            </div>
            <!-- /.row -->
        </div>
        <!-- /.container-fluid -->
    </section>
    <!-- /.content -->
</div>