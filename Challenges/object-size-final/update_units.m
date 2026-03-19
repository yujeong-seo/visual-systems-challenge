% Handling mm/cm unit conversions in modal UI

function update_units(bg_unit, fig)
    meas_all = getappdata(fig, 'meas_all');
    if isempty(meas_all); return; end

    use_cm = strcmp(bg_unit.SelectedObject.Text, 'cm');

    for k = 1:numel(meas_all)
        m = meas_all(k);
        if use_cm
            m.lbl_long.Text  = sprintf('Long side:   %.2f cm',    m.obj_long_mm  / 10);
            m.lbl_short.Text = sprintf('Short side:  %.2f cm',    m.obj_short_mm / 10);
            m.lbl_perim.Text = sprintf('Perimeter:   %.2f cm',    m.obj_perim_mm / 10);
            m.lbl_area.Text  = sprintf('Area:        %.2f cm²',   m.obj_area_mm2 / 100);
            m.lbl_scale.Text = sprintf('Scale:       %.4f px/cm', m.px_per_mm * 10);
        else
            m.lbl_long.Text  = sprintf('Long side:   %.2f mm',    m.obj_long_mm);
            m.lbl_short.Text = sprintf('Short side:  %.2f mm',    m.obj_short_mm);
            m.lbl_perim.Text = sprintf('Perimeter:   %.2f mm',    m.obj_perim_mm);
            m.lbl_area.Text  = sprintf('Area:        %.2f mm²',   m.obj_area_mm2);
            m.lbl_scale.Text = sprintf('Scale:       %.4f px/mm', m.px_per_mm);
        end
    end
end
