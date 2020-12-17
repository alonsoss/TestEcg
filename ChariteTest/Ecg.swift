//
//  MedikationsPlan.swift
//  ChariteTest
//
//  Created by Alonso Essenwanger on 18.10.20.
//

import Foundation
import HealthKit

class EcgTest: ObservableObject{
    // Add code to use HealthKit here.
    let healthStore = HKHealthStore()
    
    var latestDate : Date? = nil
    
    var descriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    var predicate = HKQuery.predicateForSamples(withStart: nil, end: Date())
    var firstTime = true
    
    @Published var testID = [TestID]()
    
    
    // Function to authorize HealthKit on every start of the app
    func authorizeHealthKit() {
        let electroCarido = Set([HKObjectType.electrocardiogramType()])
        healthStore.requestAuthorization(toShare: nil, read: electroCarido) { (sucess, error) in
            if sucess {
                print("HealthKit Auth successful")
                self.readEcgData()
            } else {
                print("HealthKit Auth Error")
            }
        }
    }
    
    func readEcgData() {
        // Create the electrocardiogram sample type.
        let ecgType = HKObjectType.electrocardiogramType()
        // Query for electrocardiogram samples
        let ecgQuery = HKSampleQuery(sampleType: ecgType,
                                     predicate: predicate,
                                     limit: HKObjectQueryNoLimit,
                                     sortDescriptors: [descriptor]) { (query, samples, error) in
            if let error = error {
                // Handle the error here.
                fatalError("*** An error occurred \(error.localizedDescription) ***")
            }
            
            guard let ecgSamples = samples as? [HKElectrocardiogram] else {
                fatalError("*** Unable to convert \(String(describing: samples)) to [HKElectrocardiogram] ***")
            }
            if !ecgSamples.isEmpty && self.latestDate == nil {
                print("UP")
                self.latestDate = ecgSamples[0].startDate
                self.predicate = HKQuery.predicateForSamples(withStart: self.latestDate, end: nil)
                self.descriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            }
            
            for sample in ecgSamples {
                print("Sample \(sample.startDate) Size: \(ecgSamples.count)")
                if sample.startDate == self.latestDate! && !self.testID.isEmpty {
                    print("inside \(sample.startDate)")
                    print(ecgSamples)
                    print("LatestDate \(self.latestDate!)")
                    print("Setting lastestDate to \(ecgSamples[ecgSamples.count - 1].startDate)")
                    self.latestDate = ecgSamples[ecgSamples.count - 1].startDate
                    if(ecgSamples.count == 1 ) {
                        print("Continue \n")
                        continue
                    }
                    print("\n")
                }
                var dataDecimal = [Decimal]()
                
                let voltageQuery = HKElectrocardiogramQuery(sample) { (query, result) in
                    switch(result) {
                    case .measurement(let measurement):
                        if let voltageQuantity = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                            let voltageValue = (voltageQuantity.value(forKey: "value") as! NSNumber).decimalValue
                            dataDecimal.append(voltageValue)
                        }
                    case .done:
                        let string = self.formatValues(data: "\(dataDecimal)")
                        let observationEcg = self.createObservation(sample: sample, string: string)
                        let testIDObject = TestID.init(observationTemplate: observationEcg)
                        print("Eingefügt wird: \(sample.startDate) LatestDate: \(self.latestDate!)")
                        DispatchQueue.main.async {
                            if sample.startDate > self.latestDate! {
                                print("Appending at the beg")
                                self.testID.insert(testIDObject, at: 0)
                            } else {
                                print("Appending at the end")
                                self.testID.append(testIDObject)
                            }
                        }
                        print("Done")
                    case .error(let error):
                        print(error)
                    @unknown default:
                        print("Default")
                    }
                }
                // Execute the electrocardiogram query
                self.healthStore.execute(voltageQuery)
            } 
        }
        // Execute the sample query.
        healthStore.execute(ecgQuery)
    }
    
    func createObservation(sample : HKElectrocardiogram, string : String) -> ObservationTemplate {
        let name = "Alonso Essenwanger"
        let deviceInit = Device.init(display: sample.sourceRevision.productType ?? "Old Device")
        let effectiveDateTime = self.getISODateFromDate(unix: sample.startDate)
        let performerInit = Performer.init(display: name, reference: name)
        let subjectInit = Subject.init(display: name, reference: name)
        let valueSampleDataInit = ValueSampledData.init(data: string, origin: Origin.init())
        let componenValuesInit = ComponentValues.init(valueSampledData: valueSampleDataInit)
        return ObservationTemplate.init(device: deviceInit, component: [componenValuesInit], subject: subjectInit, performer: [performerInit], effectiveDateTime: effectiveDateTime)
    }
    
    func formatValues(data : String) -> String {
        return data.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: ",", with: "")
    }
    
    func getISODateFromDate(unix : Date) -> String {
        return ISO8601DateFormatter().string(from: unix)
    }
    
    func printJSON(observation : ObservationTemplate) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try! encoder.encode(observation)
        print(String(data: data, encoding: .utf8)!)
    }
    
    func getJSONString(observation : ObservationTemplate) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        let data = try! encoder.encode(observation)
        return String(data: data, encoding: .utf8)!
    }
}
