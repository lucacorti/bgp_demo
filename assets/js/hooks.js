import * as echarts from "../node_modules/echarts";
const hooks = {};

hooks.Chart = {
  mounted() {
    selector = "#" + this.el.id;
    this.chart = echarts.init(
      this.el.querySelector(selector + "-chart"),
      "dark",
    );
    option = JSON.parse(this.el.querySelector(selector + "-data").textContent);
    this.chart.setOption(option);
  },
  updated() {
    selector = "#" + this.el.id;
    option = JSON.parse(this.el.querySelector(selector + "-data").textContent);
    this.chart.setOption(option);
  },
};

export default hooks;
